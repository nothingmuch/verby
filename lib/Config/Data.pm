#!/usr/bin/perl

package Config::Data;

use strict;
use warnings;

use Scalar::Util qw/weaken/;

sub new {
	my $pkg = shift;
	my $parent = shift;

	my $self = bless {}, $pkg;

	if ($parent) {
		$self->{parent} = $parent;
		weaken($self->{parent});
		tie my %data, "Tie::HashDefaults", $parent->data;
		$self->{data} = \%data;;
	}

	$self;
}

sub AUTOLOAD {
	my $self = shift;
	(our $AUTOLOAD) =~ /::([^:]+)$/;

	my $field = $1;

	$self->get($field);
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

__PACKAGE__

__END__

=pod

=head1 NAME

Config::Data - 

=head1 SYNOPSIS

	use Config::Data;

=head1 DESCRIPTION

=cut
