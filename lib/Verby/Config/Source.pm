#!/usr/bin/perl

package Verby::Config::Source;
use base qw/Verby::Config::Data/;

use strict;
use warnings;

use Tie::Memoize;

sub new {
	my $pkg = shift;

	my $self;
	tie my %data, 'Tie::Memoize', sub { $self->get_key(shift) };

	$self = bless { data => \%data }, $pkg;
}

sub get_key {
	die "subclass should extract keys from real config source";
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Config::Source - 

=head1 SYNOPSIS

	use Verby::Config::Source;

=head1 DESCRIPTION

=cut
