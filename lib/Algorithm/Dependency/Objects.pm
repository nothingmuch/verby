#!/usr/bin/perl

package Algorithm::Dependency::Objects;
use base qw/Class::Accessor/;

use strict;
use warnings;

use Set::Object;
use List::MoreUtils qw/all/;
use Params::Validate;
use Carp qw/croak/;

__PACKAGE__->mk_ro_accessors(qw/objects selected/);

my %valid_set = (
	isa => "Set::Object",
	callbacks => {
		"all members ->can('depends')" => sub {
			all { $_->can("depends") } $_[0]->members;
		},
	},
);

sub new {
	my $pkg = shift;
	my $self = bless { validate(@_, {
		objects => \%valid_set,
		selected => { %valid_set, default => Set::Object->new },
	}) }, $pkg;

	croak "selected objects aren't a subset of controlled objects"
		unless $self->selected->subset($self->objects);

	$self;
}

sub depends {
	my $self = shift;
	my @queue = grep { $_->depends } @_;

	my $deps = Set::Object->new;
	my $sel = $self->selected;
	my $objs = $self->objects;

	while (@queue){
		my $obj = shift @queue;
		croak "$obj is not in objects!"
			unless $objs->contains($obj);
		next if $sel->contains($obj);
		next if $deps->contains($obj);

		my @new = Set::Object->new($obj->depends)->difference($sel)->members;
		push @queue, @new;
		$deps->insert(@new);
	}

	$deps->members;
}

sub schedule {
	my $self = shift;
	my $sel = $self->selected;

	return (
		$self->depends(@_),
		Set::Object->new(@_)->difference($self->selected)->members, # remove selected items
	);
}

sub schedule_all {
	my $self = shift;
	$self->objects->difference($self->selected)->members;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Algorithm::Dependency::Objects - 

=head1 SYNOPSIS

	use Algorithm::Dependency::Objects;

=head1 DESCRIPTION

=cut
