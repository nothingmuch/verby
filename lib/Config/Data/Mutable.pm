#!/usr/bin/perl

package Config::Data::Mutable;
use base qw/Config::Data/;

use strict;
use warnings;

sub set {
	my $self = shift;
	my $field = shift;
	my $value = shift;

	$self->{data}{$field} = $value;
}

sub export {
	my $self = shift;
	my $field = shift;

	my $parent = $self->parent;
	$parent->set($field, $self->$field);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Config::Data::Mutable - 

=head1 SYNOPSIS

	use Config::Data::Mutable;

=head1 DESCRIPTION

=cut
