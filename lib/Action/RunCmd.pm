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

	IPC::Run::run($cli, \($in, $out), sub {
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

Action::RunCmd - 

=head1 SYNOPSIS

	use Action::RunCmd;

=head1 DESCRIPTION

=cut
