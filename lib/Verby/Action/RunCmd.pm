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
	
	my $in = $opts{in};
	my ($out, $err);

	my $init = shift;

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

	use Verby::Action::RunCmd;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<run \@CLI, $stdin, sub { init }>

This is basically a wrapper around L<IPC::Run/run> which knows how to log with our system.

The CLI array ref is sent to IPC::Run.

$stdin is a parameter in the same format passed to IPC::Run. It can be a
filename, a ref to a scalar, a code ref, etc.

The init sub is run after the fork, before the exec. Normally you use it like:

	sub { chdir $workdir }

Stdout is collected into a variable.

Stderr is collected into a variable, and logged in real time using the log level C<warn>.

=item B<finish>

=item B<pump>

=item B<log_extra>

=item B<log_invocation>

=item B<cmd_start>

=item B<cmd_finish>

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
