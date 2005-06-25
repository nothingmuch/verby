#!/usr/bin/perl

package Verby::Action::RunCmd;
use base qw/Verby::Action/;

use strict;
use warnings;

our $VERSION = '0.01';

use IPC::Run ();

sub run {
	my $self = shift;

	$self->cmd_start(@_);
	$self->cmd_finish(@_);
}

sub cmd_start {
	my $self = shift;
	my $c = shift;
	my $cli = shift;
	my %opts = (log_stderr => 1, %{ shift @_ || {} });

	$self->log_invocation($c, "running '@$cli'");

	my $init = $opts{init};
	
	my $in = $opts{in};
	my ($out, $err);

	my $mk_log_handler = sub {
		my $name = shift;
		my $var_ref = shift;

		return sub {
			${$var_ref} .= "@_";
		
			my $output = "@_";
			chomp($output) if ($output =~ tr/\n// == 1); # if it's one line, trim it
			foreach my $line (split /\n/, $output){ # if it's not split it looks chaotic
				$c->logger->warn("$name: $line");
			}
		}
	};

	my $err_arg = ($opts{log_stderr} ? $mk_log_handler->(stderr => \$err) : \$err);
	my $out_arg = ($opts{log_stdout} ? $mk_log_handler->(stdout => \$out) : \$out); 

	my $h = IPC::Run::start($cli, ($in || ()), ">", $out_arg, "2>", $err_arg, ($init ? (init => $init) : ()))
		or $c->logger->logdie("subcommand '@$cli' could not be started: \$!='$!'");

	$c->cmd_line($cli);
	$c->cmd_handle($h);
	$c->stdout_ref(\$out);
	$c->stderr_ref(\$err);
}

sub finish {
	my $self = shift;
	my $c = shift;

	$self->cmd_finish($c);

	$c->confirm($c);
}

sub pump {
	my $self = shift;
	my $c = shift;

	my $h = $c->cmd_handle;

	return unless $h->pumpable;

	$h->pump_nb;
	return 1;
}

sub cmd_finish {
	my $self = shift;
	my $c = shift;

	my $h = $c->cmd_handle;

	$c->logger->info("finishing command '@{ $c->cmd_line }'");
	
	IPC::Run::finish($h)
		or $c->logger->logdie("subcommand '@{ $c->cmd_line }' failed with exit code $?");

	my $out = ${ $c->stdout_ref };
	my $err = ${ $c->stderr_ref };
	
	return ($out, $err);
}

sub log_invocation {
	my $self = shift;
	my $c = shift;
	my $msg = shift;

	$c->logger->info($msg . $self->log_extra($c));
}

sub log_extra { "" }

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::RunCmd - a base class for actions which exec external commands.

=head1 SYNOPSIS

	use base qw/Verby::Action::RunCmd/; # not usable on it's own
	
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

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
