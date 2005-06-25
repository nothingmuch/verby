#!/usr/bin/perl

package Action::RunCmd;
use base qw/Action/;

use strict;
use warnings;

use IPC::Run;

sub run {
	my $self = shift;
	my $c = shift;
	my $cli = shift;

	$self->log_invocation($c, "running '@$cli'");
	
	my $in = shift;
	my ($out, $err);

	my $init = shift;

	IPC::Run::run($cli, ($in || ()), ">", \$out, "2>", sub {
		$err .= "@_";
		
		my $output = "@_";
		chomp($output) if ($output =~ tr/\n// == 1); # if it's one line, trim it
		$c->logger->warn("stderr: $output");
	}, ($init ? (init => $init) : ())) or $c->logger->logdie("subcommand '@$cli' failed: \$!='$!'");

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

Action::RunCmd - a base class for actions which exec external commands.

=head1 SYNOPSIS

	use Action::RunCmd;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item run \@CLI, $stdin, sub { init }

This is basically a wrapper around L<IPC::Run/run> which knows how to log with our system.

The CLI array ref is sent to IPC::Run.

$stdin is a parameter in the same format passed to IPC::Run. It can be a
filename, a ref to a scalar, a code ref, etc.

The init sub is run after the fork, before the exec. Normally you use it like:

	sub { chdir $workdir }

Stdout is collected into a variable.

Stderr is collected into a variable, and logged in real time using the log level C<warn>.

=back

=cut