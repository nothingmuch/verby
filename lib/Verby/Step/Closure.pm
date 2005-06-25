#!/usr/bin/perl

package Verby::Step::Closure;
use base qw/Verby::Step Class::Accessor/;

use strict;
use warnings;

use UNIVERSAL::require;
use overload '""' => 'stringify';

use Carp qw/croak/;

sub import {
    shift;            # remove pkg
    return unless @_; # dont export it if they dont ask
	no strict 'refs';
    *{ (caller())[0] . "::step"} = \&step if $_[0] eq 'step';
}

__PACKAGE__->mk_accessors(qw/action depends pre post provides_cxt/);

sub add_deps {
	my $self = shift;
	$self->depends($self->depends, @_);
}

sub get {
	my $self = shift;
	my $rv = $self->SUPER::get(@_);

	(ref $rv eq "ARRAY") ? @$rv : $rv;
}

sub set {
	my $self = shift;
	my $key = $_[0];

	$self->SUPER::set(@_);
}

sub new {
	my $pkg = shift;
	my $pre = shift;
	my $post = shift;

	my $self = bless {
		depends => [],
		pre => $pre,
		post => $post,
	}, $pkg;

	$self;
}

sub is_satisfied {
	my $self = shift;
	$self->_wrapped("verify", @_);
}

sub do {
	my $self = shift;
	$self->_wrapped("do", @_);
}

sub start {
	my $self = shift;
	$self->_wrapped("start", @_);
}

sub finish {
	my $self = shift;
	$self->_wrapped("finish", @_);
}

sub pump {
	my $self = shift;
	$self->action->pump(@_);
}

sub can {
	my $self = shift;
	my $method = shift;

	# only claim we can start/finish if our action can
	if ($method eq "start" or $method eq "finish" or $method eq "pump"){
		return $self->action->can($method);
	} else {
		return $self->SUPER::can($method);
	}
}

sub _wrapped {
	my $self = shift;
	my $action_method = shift;
	
	if ($action_method ne "finish" and my $sub = $self->pre){
		$self->$sub(@_);
	}

	my $rv = $self->action->$action_method(@_);

	if ($action_method ne "start" and my $post = $self->post){
		$self->$post(@_);
	}

	$rv;
}

sub step ($;&&) {
	my $action_class = shift;

	my $step = Verby::Step::Closure->new(@_);

	$action_class->require
		or die "Couldn't require $action_class: $UNIVERSAL::require::ERROR"
			unless $action_class->can("new");
	$step->action($action_class->new);

	$step;
}

sub stringify {
	my $self = shift;
	ref $self->action || $self->action;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Step::Closure - Quick and dirty (in the fun sense, like playing with
mud) step generator.

=head1 SYNOPSIS

	use Verby::Step::Closure qw/step/;

	my $s = step "Action::Class" => sub {
		# called before action
	}, sub {
		# called after action
	};

=head1 DESCRIPTION

This module eases the creation of step objects, by using closures and
accessors. It's purpose is to be able to rapidly create simple steps based on
an action class and some clalbacks.

Since L<Verby::Action> and L<Verby::Step> are separated, this may lead to
unnecessary typing, class creation, or other silly crap.
L<Verby::Step::Closure>'s purpose is to make this boundry unnoticable, so that
when you don't need it it doesn't get in your way.

=head1 FUNCTIONS

=over 4

=item step $action_class ?$pre ?$post

This function (optionally exportable) is used as a quick and dirty constructor.

It will require $action_class with L<UNIVERSAL::require>, and then create a new
L<Verby::Step::Closure> with the C<action> field set to an instance.

=back

=head1 METHODS

=over 4

=item new $action_class ?$pre ?$post

Creates a new anonymous step.

=item depends *@steps

Just a plain old accessor.

=item add_deps *@steps

Append more steps to the dep list.

=item is_satisfied

=item finish

=item start

=item do

These methods all call the pre callback (except for C<finish>), then the
corresponding method on the action (special case: L<Action/verify> for
C<is_satisfied>), and lastly the post callback (except for C<start>).

=item pump

This just delegates to the pump method of the action.

=item stringify

Stringifies to the action's class.

=item get

=item set

Replacements for L<Class::Accessor>'s methods that convert between lists and
array references.

=item can $method

A special case of L<UNIVERSAL/can> that will return false for methods the
action can't fulfill.

=item

=back

=head1 EXAMPLE

The test files, as well as the demo scripts make extensive use of
L<Verby::Step::Closure>.

=cut
