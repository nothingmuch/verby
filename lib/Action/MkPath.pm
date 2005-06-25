#!/usr/bin/perl

package Action::MkPath;
use base qw/Action/;

use strict;
use warnings;

use File::Path qw/mkpath/;
use Fatal qw/mkpath/;

sub do {
	my $self = shift;
	my $c = shift;

	my $path = $c->path;

	$c->logger->note(sprintf "creating path '$path'");
	mkpath($path);

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

Action::MkPath - 

=head1 SYNOPSIS

	use Action::MkPath;

=head1 DESCRIPTION

=cut
