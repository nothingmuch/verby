#!/usr/bin/perl

package Verby::Step::Simple;
use Moose::Role;

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
	push @{ $self->depends }, @_;
}

sub is_satisfied {
    my ( $self, $c, @args ) = @_;
    $self->action->verify( $c, @args );
}

__PACKAGE__;

__END__
