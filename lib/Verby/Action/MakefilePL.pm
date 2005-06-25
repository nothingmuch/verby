#!/usr/bin/perl

package Verby::Action::MakefilePL;
use base qw/Verby::Action::RunCmd/;

use strict;
use warnings;

use File::Spec;

sub start {
	my $self = shift;
	my $c = shift;

	my $wd = $c->workdir;

	$self->cmd_start($c, [qw/perl Makefile.PL/], undef, sub { chdir $wd });
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

Verby::Action::MakefilePL - 

=head1 SYNOPSIS

	use Verby::Action::MakefilePL;

=head1 DESCRIPTION

=cut
