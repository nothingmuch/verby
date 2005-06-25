#!/usr/bin/perl

package Config::Data;

use strict;
use warnings;

use Scalar::Util qw/weaken/;
use Tie::HashDefaults;
use Carp qw/croak/;

sub new {
	my $pkg = shift;
	my $parent = shift;

	my $self = bless {}, $pkg;

	if ($parent) {
		$self->{parent} = $parent;
		weaken($self->{parent});
		tie my %data, "Tie::HashDefaults", $parent->data;
		$self->{data} = \%data;;
	} else { $self->{data} = {} };

	$self;
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
	$self->{data}{$key};
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

sub parent {
	my $self = shift;
	$self->{parent};
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
