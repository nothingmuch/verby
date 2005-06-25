#!/usr/bin/perl

package Action::MakefilePL;
use base qw/Action/;

use strict;
use warnings;

use IPC::Run qw/run/;
use Fatal qw/run/;
use File::Spec;

sub do {
	my $self = shift;
	my $c = shift;

	my $wd = $c->workdir;

	$c->logger->note("running Makefile.PL in '$wd'");

	run[qw/perl -e /, 'chdir shift; do "Makefile.PL" or die $!', $wd], \(my ($in, $out, $err));

	warn "stderr: $err";

	$self->confirm($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

	-e File::Spec->catfile($c->workdir, "Makefile");
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::MakefilePL - 

=head1 SYNOPSIS

	use Action::MakefilePL;

=head1 DESCRIPTION

=cut
