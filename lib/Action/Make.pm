#!/usr/bin/perl

package Action::Make;
use base qw/Action/;

use strict;
use warnings;

use IPC::Run qw/run/;
use Fatal qw/run/;

sub do {
	my $self = shift;
	my $c = shift;

	my $wd = $c->workdir;
	my @targets = (($c->target || ()), @{ $c->targets || [] });

	$c->logger->note("running make @targets in $wd");

	run [qw/make -C/, $wd, @targets], \(my ($in, $out, $err));

	print "$out" if "@targets" eq "test";
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
