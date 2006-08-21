#!/usr/bin/perl

package Verby::Action::Run;
use Moose::Role;

with qw/Verby::Action/;

use Carp qw/croak/;

use POE qw/Wheel::Run Filter::Stream/;

sub create_poe_session {
	my ( $self, %heap ) = @_;
	$heap{log_stderr} = 1 unless exists $heap{log_stderr};

	my $accum = $heap{accum} ||= {};

	foreach my $output ( qw/stdout stderr/ ) {
		next if exists $accum->{$output};
		$accum->{$output} = "";
	}

	POE::Session->create(
		object_states => [
			$self => { $self->poe_states(\%heap) },
		],
		heap => \%heap,
	);
}

sub poe_states {
	my ( $self, $heap ) = @_;
	return (
		_start  => "poe_start",
		_stop   => "poe_stop",
		_parent => "poe_parent",
		(map { ("std$_") x 2 } qw/in out err/),
		(map { ($_) x 2 } qw/
			error
			close
			sigchld_handler
			DIE
			/),
	);
}

sub confirm_exit_code {
	my ( $self, $c ) = @_;
	$c->logger->logdie("subprogram " . $c->program_debug_string . " exited with non zero status: " . $c->program_exit)
		unless $c->program_exit == 0;
}

sub poe_start {
	my ( $self, $kernel, $session, $heap ) = @_[OBJECT, KERNEL, SESSION, HEAP];

	$self->setup_wheel( $kernel, $session, $heap );
}

sub poe_parent {
	$_[HEAP]{c}->logger->debug("Attached to parent");
}

sub sigchld_handler {
    my ( $self, $kernel, $session, $heap, $pid, $child_error ) = @_[ OBJECT, KERNEL, SESSION, HEAP, ARG1, ARG2 ];
    return unless exists $heap->{pid_to_wheel}{$pid};
	
    my $wheel = delete $heap->{pid_to_wheel}{$pid};
    delete $heap->{id_to_wheel}{ $wheel->ID };

	$kernel->sig( "CHLD" ) unless scalar keys %{ $heap->{id_to_wheel} };
	
	$heap->{program_exit} = $child_error;
}

sub setup_wheel {
	my ( $self, $kernel, $session, $heap ) = @_;

	my $wheel = $self->create_wheel( $heap );

	$kernel->sig( CHLD => "sigchld_handler" );

	$heap->{pid_to_wheel}->{ $wheel->PID } = $wheel;
	$heap->{id_to_wheel}->{ $wheel->ID }   = $wheel;

	$self->send_child_input( $wheel, $heap );
}

sub create_wheel {
	my ( $self, $heap ) = @_;

	my $wheel = POE::Wheel::Run->new(
		Program => $self->wheel_program( $heap ),

		$self->default_poe_wheel_events( $heap ),

		$self->additional_poe_wheel_options( $heap ),
	);
	
	$self->log_invocation($heap->{c}, "started $heap->{program_debug_string}");

	return $wheel;
}

sub additional_poe_wheel_options {
	my ( $self, $heap ) = @_;
	return (
		StdinFilter  => POE::Filter::Stream->new(),
		StdoutFilter => POE::Filter::Stream->new(),
		StderrFilter => POE::Filter::Stream->new(),
	);
}

sub default_poe_wheel_events {
	my ( $self, $heap ) = @_;
	return (
		StdinEvent  => "stdin",
		StdoutEvent => "stdout",
		StderrEvent => "stderr",
		ErrorEvent  => "error",
		CloseEvent  => "close",
	);
}

sub wheel_program {
	my ( $self, $heap ) = @_;

	if ( my $program = $heap->{program} ) {
		$heap->{program_debug_string} ||= "'$program'";
		return $program
	} elsif( my $cli = $heap->{cli} ) {
		if ( my $init = $heap->{init} ) {
			$heap->{program_debug_string} ||= "'@$cli' with init block";
			return sub { $init->(); exec(@$cli) };
		} else {
			$heap->{program_debug_string} ||= "'@$cli'";
			return $cli;
		}
	} else {
		croak "Either 'program' or 'cli' must be provided";
	}
}

sub send_child_input {
	my ( $self, $wheel, $heap ) = @_;

	if ( my $in = $heap->{in} ) {
		if ( ref($in) eq "SCALAR" ) {
			$in = $$in;
			$heap->{in} = undef;
		} else {
			$in = $in->();
			$heap->{in} = undef unless defined $in;
		}

		$wheel->put( $in );
	} else {
		$wheel->shutdown_stdin;
	}
}

sub DIE {
	my ( $heap, $exception ) = @_[HEAP, ARG0];
	push @{ $heap->{exceptions} ||= [] }, $exception;
}

sub poe_stop {
	my ( $self, $kernel, $heap ) = @_[OBJECT, KERNEL, HEAP];

	$heap->{c}->logger->info("Wheel::Run subsession closing");

	if ( scalar keys %{ $heap->{pid_to_wheel} } ) {
		require Data::Dumper;
		die "AAAAAAAHHH Running proces!" . Data::Dumper::Dumper($heap);
	}

	my $c = $heap->{c};

	$c->command_line( $heap->{cli} ) if exists $heap->{cli};
	$c->program( $heap->{program} ) if exists $heap->{program};
	$c->program_debug_string( $heap->{program_debug_string} );
	$c->stdout( $heap->{accum}{stdout} );
	$c->stderr( $heap->{accum}{stderr} );
	$c->program_exit( $heap->{program_exit} >> 8 );
	$c->program_exit_full( $heap->{program_exit} );

	$c->program_finished(1);

	$self->confirm_exit_code($c);

	$self->finished($c) if $self->can("finished");
}

sub error {
	my ( $self, $heap ) = @_[OBJECT, HEAP];
	#$heap->{c}->logger->info("subprogram $heap->{program_debug_string} error: @_[ARG0 .. $#_]");
}

sub stdin {
	my ( $self, $heap, $wheel_id ) = @_[OBJECT, HEAP, ARG0];
	$self->send_child_input( $heap->{id_to_wheel}{$wheel_id}, $heap );
}

sub stdout {
	my ( $self, $heap, $output ) = @_[OBJECT, HEAP, ARG0];
	$heap->{accum}{stdout} .= $output;
	$self->log_output( $heap->{c}, "stdout", $output ) if $heap->{log_stdout};
}

sub stderr {
	my ( $self, $heap, $output ) = @_[OBJECT, HEAP, ARG0];
	$heap->{accum}{stderr} .= $output;
	$self->log_output( $heap->{c}, "stderr", $output ) if $heap->{log_stderr};
}

sub log_output {
	my ( $self, $c, $name, $output ) = @_;

	chomp($output) if ($output =~ tr/\n// == 1); # if it's one line, trim it
	foreach my $line (split /\n/, $output){ # if it's not split it looks chaotic
		$c->logger->warn("$name: $line");
	}
}

sub close {
	my ( $self, $heap ) = @_[OBJECT, HEAP];
	$heap->{c}->logger->info("finishing program $heap->{program_debug_string}");
}

sub log_invocation {
	my ( $self, $c, $msg ) = @_;

	$c->logger->info($msg . $self->log_extra($c));
}

sub log_extra { "" }

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::RunCmd - a base role for actions which wrap L<POE::Wheel::Run>.

=head1 SYNOPSIS

	package MyAction;
	use Moose;

	with qw/Verby::Action::RunCmd/;
	
	sub start {
		my ($self, $c) = @_;
		blah();
		$self->cmd_start($c, [qw/touch file/]);
	}

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<run @args_for_cmd_start>

The method to be used by your action's C<do> method when appropriate.

Basically a thin wrapper arund C<cmd_start> and C<cmd_finish>, that lazy people
will like.

=item B<cmd_start $cxt, \@command_line, [ \%opts ]>

The method to be used by your action's C<start> method when appropriate.

The first parameter is the context, as is typical in L<Verby>.

The second parameter is an array reference of the command line to invoke. This
is passed verbatim to L<IPC::Run>.

The third, optional parameter, is a hash reference of options.

The option fields that you can use are

=over 4

=item init

A code reference, corresponding to L<IPC::Run>'s init parameter.

=item log_stderr

A boolean (true by default), that causes the C<STDERR> handler to be a delegate
to the logger.

=item log_stdout

The same as C<log_stderr> but for C<STDOUT>. False by default.

=item in

A parameter to be passed as the input to L<IPC::Run>. This can be a string ref,
a code ref, or, whatever. See L<IPC::Run>'s docs.

=back

=item C<cmd_finish>

The inverse of C<cmd_start> - causes an OS image to be restored, for the time
just prior to the invocation of C<cmd_start>. Only works on the EROS operating
system.

On other operating systems, it waits for the child process to finish.

=item B<finish>

A default implementation of L<Verby::Action/finish> that'll call C<cmd_finish>
and then L<Verby::Action/confirm>.

=item B<pump>

See if the process finished. Part of the L<Verby::Action> async interface.

=item B<log_extra>

A method that given the context might append something to log messages. used by
L<Verby::Action::Make>, for example.

=item B<log_invocation>

Mostly internal - the default implementation of the logging operation used when
invoking the subcommand.

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we
will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to
COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

L<Verby::Action::Copy> - a L<Verby::Action::RunCmd> subclass.

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005, 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
