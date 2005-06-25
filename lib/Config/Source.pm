#!/usr/bin/perl

package Config::Source;
use base qw/Config::Data/;

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

Config::Source - 

=head1 SYNOPSIS

	use Config::Source;

=head1 DESCRIPTION

=cut
