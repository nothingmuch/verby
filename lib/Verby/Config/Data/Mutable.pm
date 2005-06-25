#!/usr/bin/perl

package Verby::Config::Data::Mutable;
use base qw/Verby::Config::Data/;

use strict;
use warnings;

use Carp qw/croak/;

sub set {
	my $self = shift;
	my $field = shift;
	my $value = shift;

	$self->{data}{$field} = $value;
}

sub export {
	my $self = shift;
	my $field = shift;

	if ($self->exists($field)){
		my $value = $self->extract($field);
		foreach my $parent ($self->parents){
			$parent->set($field, $value);
		}
	} else {
		croak "key $field does not exist in $self";
	}
}

sub export_all {
	my $self = shift;
	foreach my $field (keys %{ $self->{data} }){
		$self->export($field);
	}
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Config::Data::Mutable - 

=head1 SYNOPSIS

	use Verby::Config::Data::Mutable;

=head1 DESCRIPTION

=cut
