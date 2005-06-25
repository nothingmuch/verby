#!/usr/bin/perl

package Step::Closure;
use base qw/Step Class::Accessor/;

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

sub get {
	my $self = shift;
	my $rv = $self->SUPER::get(@_);

	UNIVERSAL::isa($rv, "ARRAY") ? @$rv : $rv;
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

sub can {
	my $self = shift;
	my $method = shift;

	# only claim we can start/finish if our action can
	if ($method eq "start" or $method eq "finish"){
		$self->action->can($method) and $self->SUPER::can($method);
	} else {
		$self->SUPER::can($method);
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

	my $step = Step::Closure->new(@_);

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

Step::Closure - Reusable generic step with a closure as it's body.

=head1 SYNOPSIS

	use Step::Closure;

=head1 DESCRIPTION

=cut
