#!/usr/bin/perl

package Config::Data::Mutable;
use base qw/Config::Data/;

use strict;
use warnings;

sub AUTOLOAD {
	# TODO
	# consider merging this AUTOLOAD into Config::Data, and let it to ->set if
	# $self isa ::Mutable, so that we can cache closures.
	(our $AUTOLOAD) =~ /::([^:]+)$/;

	my $field = $1;

	my $sub = sub {
		my $self = shift;
		$self->set($field, @_) if @_;
		$self->get($field);
	};

	{
		no strict;
		*{ $field } = $sub;
	}

	goto &$sub;
}

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
	die "parent of $self is immutable" unless $parent->isa(__PACKAGE__);
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
