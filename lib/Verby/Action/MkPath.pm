#!/usr/bin/perl

package Verby::Action::MkPath;
use base qw/Verby::Action/;

use strict;
use warnings;

use File::Path qw/mkpath/;

sub do {
	my $self = shift;
	my $c = shift;

	my $path = $c->path;

	$c->logger->info("creating path '$path'");
	mkpath($path)
		or $c->logger->logdie("couldn't mkpath('$path'): $!");

	$self->confirm($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

	-d $c->path;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::MkPath - 

=head1 SYNOPSIS

	use Verby::Action::MkPath;

=head1 DESCRIPTION

=cut
