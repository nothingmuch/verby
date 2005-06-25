#!/usr/bin/perl

package Step::Source;
use base qw/Algorithm::Dependency::Source/;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my $items = shift;

	my $self = $pkg->SUPER::new;
	
	$self->{_items_arr} = $items;

	$self;
}
sub _load_item_list { $_[0]->{_items_arr} }

__PACKAGE__

__END__

=pod

=head1 NAME

Step::Source - a mock L<Algorithm::Dependency::Source> object.

=head1 SYNOPSIS

	my @items = (...);
	
	my $src = Step::Source->new(\@items);
	$src->items; # @items

=head1 DESCRIPTION

Array::Dependency does not call $obj->isa, but rather UNIVERSAL::isa. This
means we can't use Test::MockObject for all it's goodness, and this ugly hack
is used instead.

=head1 METHODS

=over 4

=item new \@items

Creates a new object whose L<_load_item_list> will return the items in the
given array reference.

=item _load_item_list

Used internally by L<Algorithm::Dependency::Source/load>.

=back

=cut

