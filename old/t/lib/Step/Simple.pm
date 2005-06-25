#!/usr/bin/perl

package Step::Simple;
use base qw/EERS::Step/;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	bless { @_ }, $pkg;
}

sub depend_on {
	my $self = shift;
	$self->{depends} = [ map { $_->id } @_ ];
}

sub depends { @{ $_[0]{depends} ||= [] } }
sub execute { $_[0]->log_event("executed") }

sub log_event {
	my $self = shift;
	push @{ $self->{log} }, { type => shift, obj => $self };
}

__PACKAGE__

__END__

=pod

=head1 NAME

Step::Simple - a mock EERS::Step with recording facilities.

=head1 SYNOPSIS

	use Step::Simple;

=head1 DESCRIPTION

We can't use Test::MockObject because Array::Dependency uses UNIVERSAL::isa as
function.

=head1 METHODS

=over 4

=item new key => value, ...

Creates a new step with the given keys in it's structure.

Keys which matter are:

=over 4

=item id

The ID to return from L<EERS::Step/id>

=item log

The array reference into which C<log_event> writes.

=back

=item depend_on @steps

Takes some other step objects, and say that we depend on them.

=item depends

Returns an array reference of the IDs of the steps we depend on. Used by
L<Algorithm::Dependency>.

=item execute

Logs the "executed" event.

=item log_event

Logs an event in the log.

=back

=cut
