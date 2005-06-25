#!/usr/bin/perl

package Verby::Step::Closure;
use base qw/Verby::Step/;

use strict;
use warnings;

our $VERSION = '0.01';

use overload '""' => 'stringify';

use UNIVERSAL::require;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

# stevan hates Exporter, so this is not a bug ;-)
sub import {
    shift;            # remove pkg
    return unless @_; # dont export it if they dont ask
	no strict 'refs';
    *{ (caller())[0] . "::step"} = \&step if $_[0] eq 'step';
}

# he also hates Class::Accessor, so don't tell him I left this in
#__PACKAGE__->mk_accessors(qw/action depends pre post provides_cxt/);
# shhh, don't tell Yuval I took out his Class::Accessor stuff

sub new {
	my $pkg = shift;
	my $pre = shift;
	my $post = shift;

	my $self = bless {
		depends => [],
		pre => $pre,
		post => $post,
		action => undef,
		provides_cxt => undef,
	}, $pkg;

	$self;
}

sub depends {
    my ($self, @depends) = @_;
    $self->{depends} = [ @depends ] if scalar @depends;
    @{$self->{depends}};
}

sub action {
    my $self = shift;
    $self->{action} = shift if @_;
    $self->{action};
}

sub pre {
    my $self = shift;
    $self->{pre} = shift if @_;
    $self->{pre};
}

sub post {
    my $self = shift;
    $self->{post} = shift if @_;
    $self->{post};
}

sub provides_cxt {
    my $self = shift;
    $self->{provides_cxt} = shift if @_;
    $self->{provides_cxt};
}

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
	my $action = shift;

	my $step = Verby::Step::Closure->new(@_);

	unless (blessed $action){
		unless ($action->can("new")){
			$action->require
				or die "Couldn't require $action: $UNIVERSAL::require::ERROR";
		}
		$action = $action->new;
	}

	$step->action($action);

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

=head1 EXPORTED FUNCTIONS

=over 4

=item B<step $action_class ?$pre ?$post>

This function (optionally exportable) is used as a quick and dirty constructor.

It will require $action_class with L<UNIVERSAL::require>, and then create a new
L<Verby::Step::Closure> with the C<action> field set to an instance.

=back

=head1 METHODS

=over 4

=item B<new $action_class ?$pre ?$post>

Creates a new anonymous step.

=item B<depends *@steps>

Just a plain old accessor.

=item B<add_deps *@steps>

Append more steps to the dep list.

=item B<is_satisfied>

=item B<finish>

=item B<start>

=item B<do>

These methods all call the pre callback (except for C<finish>), then the
corresponding method on the action (special case: L<Action/verify> for
C<is_satisfied>), and lastly the post callback (except for C<start>).

=item B<pump>

This just delegates to the pump method of the action.

=item B<stringify>

Stringifies to the action's class.

=item B<get>

=item B<set>

Replacements for L<Class::Accessor>'s methods that convert between lists and
array references.

=item B<can $method>

A special case of L<UNIVERSAL/can> that will return false for methods the
action can't fulfill.

=back

=head1 EXAMPLE

The test files, as well as the demo scripts make extensive use of
L<Verby::Step::Closure>. Look at F<scripts/module_builder.pl> for some
documented usage.

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
