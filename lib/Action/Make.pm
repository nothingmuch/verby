#!/usr/bin/perl

package Action::Make;
use base qw/Action::RunCmd/;

use strict;
use warnings;

sub do {
	my $self = shift;
	my $c = shift;

	my $wd = $c->workdir;
	my @targets = (($c->target || ()), @{ $c->targets || [] });

	my ($out, $err) = $self->run($c, [qw/make -C/, $wd, @targets]);

	chomp($out) and $c->logger->info("test output:\n$out") if "@targets" eq "test";
}

sub log_extra {
	my $self = shift;
	my $c = shift;

	" in " . $c->workdir;
}

sub verify { undef }; # make does this kind of behavior for us

__PACKAGE__

__END__

=pod

=head1 NAME

Action::Make - 

=head1 SYNOPSIS

	use Action::Make;

=head1 DESCRIPTION

=cut
