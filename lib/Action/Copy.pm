#!/usr/bin/perl

package Action::Copy;
use base qw/Action::RunCmd/;

use strict;
use warnings;

use File::Rsync;

sub start {
	my $self = shift;
	my $c = shift;

	my $source = $c->source;
	my $dest = $c->dest;

	$c->logger->info("copying tree from '$source' to '$dest'");

	my $r = File::Rsync->new({ archive => 1, delete => 1 }) or $c->logger->logdie("couldn't create rsync obj");
	my $cmd = $r->getcmd({ src => $source, dest => $dest }) or $c->logger->logdie("couldn't determine rsync command to run");
	
	$self->cmd_start($c, $cmd, { log_stdout => 1 });
}

sub finish {
	my $self = shift;
	my $c = shift;

	$c->done(1);
	$self->SUPER::finish($c);
}

sub verify {
	$_[1]->done;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::Copy - 

=head1 SYNOPSIS

	use Action::Copy;

=head1 DESCRIPTION

=cut
