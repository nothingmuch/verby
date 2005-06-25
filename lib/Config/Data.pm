#!/usr/bin/perl

package Config::Data;

use strict;
use warnings;

use Scalar::Util qw/weaken/;
use List::MoreUtils qw/uniq/;
use Carp qw/croak/;

sub new {
	my $pkg = shift;

	my $self = bless {
		data => {},
		parents => [ uniq @_ ],
	}, $pkg;

	weaken($_) for @{ $self->{parents} };

	$self;
}

sub DESTROY {
	my $self = shift;
	untie %{ $self->{data} } if tied $self->{data};
}

sub AUTOLOAD {
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
	croak "$self is not mutable";
}

sub get {
	my $self = shift;
	my $key = shift;
	($self->search($key) || return)->extract($key);
}

sub extract {
	my $self = shift;
	my $key = shift;
	$self->{data}{$key};
}

sub exists {
	my $self = shift;
	my $key = shift;
	exists $self->{data}{$key};
}

sub search {
	my $self = shift;
	my $key = shift;

	my @candidates = ($self);
	while (@candidates) {
		my @providers = grep { $_->exists($key) } @candidates;
		return $providers[0] if @providers == 1;
		@candidates = uniq map { $_->parents } @candidates;
	}

	return;
}

sub derive {
	my $self = shift;
	my $class = shift || ref $self;
	$class->new($self);
}

sub data {
	my $self = shift;
	$self->{data};
}

sub parents {
	my $self = shift;
	@{ $self->{parents} };
}

__PACKAGE__

__END__

=pod

=head1 NAME

Config::Data - 

=head1 SYNOPSIS

	use Config::Data;

=head1 DESCRIPTION

=cut
