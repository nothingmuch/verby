#!/usr/bin/perl

package Algorithm::Dependency::Objects::Ordered;
use base qw/Algorithm::Dependency::Objects/;

use strict;
use warnings;

use Scalar::Util qw/refaddr/;
use Carp qw/croak/;

sub schedule {
	my $self = shift;
	$self->_order($self->SUPER::schedule(@_));
}

sub schedule_all {
	my $self = shift;
	$self->_order($self->SUPER::schedule_all(@_));
}

sub _order {
	my $self = shift;
	my @queue = @_;


	my $selected = Set::Object->new->union($self->selected);

	my $error_marker;
	my @schedule;

	my %dep_set; # a cache of Set::Objects for $obj->depends

	while (@queue){
		my $obj = shift @queue;
		croak "Circular dependency detected!"
			if (defined($error_marker) and refaddr($error_marker) == refaddr($obj));
		
		my $dep_set = $dep_set{refaddr $obj} ||= Set::Object->new($obj->depends);

		unless ($dep_set->subset($selected)){
			# we have some missing deps
			# put the object back in the queue
			push @queue, $obj;

			# if we encounter it again without any change
			# then a circular dependency is detected
			$error_marker = $obj unless defined $error_marker;
		} else {
			# the dependancies are a subset of the selected objects,
			# so they are all resolved.
			push @schedule, $obj;

			# mark the object as selected
			$selected->insert($obj);

			# since something changed we can forget about the error marker
			undef $error_marker;
		}
	}

	# return the ordered list
	@schedule;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Algorithm::Dependency::Objects::Ordered - 

=head1 SYNOPSIS

	use Algorithm::Dependency::Objects::Ordered;

=head1 DESCRIPTION

=cut
