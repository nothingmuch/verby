#!/usr/bin/perl

package Action::MakefilePL;
use base qw/Action::RunCmd/;

use strict;
use warnings;

use File::Spec;

sub do {
	my $self = shift;
	my $c = shift;

	my $wd = $c->workdir;

	$self->run($c, [qw/perl Makefile.PL/], undef, sub { chdir $wd });

	$self->confirm($c);
}

sub log_extra {
	my $self = shift;
	my $c = shift;

	" in " . $c->workdir;
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
