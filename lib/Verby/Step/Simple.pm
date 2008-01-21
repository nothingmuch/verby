#!/usr/bin/perl

package Verby::Step::Simple;
use Moose::Role;

use Scalar::Util qw/refaddr/;

with qw/Verby::Step/;

sub depends {} # FIXME Moose::Role
has depends => (
	isa => "ArrayRef",
	is  => "rw",
	default    => sub { [] },
	auto_deref => 1,
);

has action => (
	isa => "Object", # "Verby::Action",
	is => "rw",
);

sub add_deps {
	my $self = shift;
	my %seen;
	$self->depends([ grep { !$seen{refaddr $_}++ } @{ $self->depends }, @_ ]);

}

sub is_satisfied {
    my ( $self, $c, @args ) = @_;
    $self->action->verify( $c, @args );
}

__PACKAGE__;

__END__
