#!/usr/bin/perl

package Verby::Step;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my $dispatcher = shift;

	my $self = bless { }, 
}

sub depends {
	die "not implemented";
}

sub is_satisfied {
	die "not implemented";
}

sub provides_cxt {
	undef;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Step - A base class representing a single thing to be executed by
L<Verby::Dispatcher>.

=head1 SYNOPSIS

	use base qw/Verby::Step/;

Or perhaps more appropriate

	use Verby::Step::Closure qw/step/;
	my $step = step "Some::Action",
		sub { warn "before" },
		sub { warn "after" };

=head1 DESCRIPTION

A step in the L<Verby> system is like an instance of an action.

A step is much like a makefile target. It can depend on other steps, and when
appropriate will be told to be executed.

The difference between a L<Verby::Step> and a L<Verby::Action> is that an
action is usually just reusable code to implement the verification and
execution

A step manages the invocation of an action, typically by massaging the context
before delegating, and re-exporting meaningful data to the parent context when
finished. It also tells the system when to execute, by specifying dependencies.

The distinction is that an action is something you do, and a step is something
you do before and after others.

=head1 METHODS

All methods should be subclassed except for C<provides_cxt>. This class is
nearly completely virtual.

=over 4

=item depends

Subclass this to return a list of other steps to depend on.

=item is_satisfied

This method should return a true value if the step does not need to be
executed.

Typically a delegation to L<Verby::Action/verify>. They are named differently,
because C<is_satisfied> implies state. The L<Verby::Dispatcher> will sometimes
make assumptions, without asking the step to check that it is satisfied.

=item do

=item start

=item finish

=item pump

These are basically delegations to the corresponding L<Verby::Action> methods.

The only interesting thing to do here is to fudge the context up a bit. For
example, if your action assumes the C<path> key to be in the context, but you
chose C<the_path_to_the_thing> to be in your config, this is the place to do:

	sub do {
		my ($self, $c) = @_;

		# prepare for the action
		$c->path($c->the_path_to_the_thing);

		$self->action->do($c);

		# pass data from the action to the next steps
		$c->export("some_key_the_action_set");
	}

L<Verby::Step::Closure> provides a convenient way to get this behavior for
free.

=back

=cut
