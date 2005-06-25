#!/usr/bin/perl

package Step::Closure;
use base qw/Step Class::Accessor Exporter/;

use strict;
use warnings;

use UNIVERSAL::require;
use overload '""' => 'stringify';

use Carp qw/croak/;

our @EXPORT_OK = qw/step/;

__PACKAGE__->mk_accessors(qw/action depends code post/);

sub get {
	my $self = shift;
	my $rv = $self->SUPER::get(@_);

	UNIVERSAL::isa($rv, "ARRAY") ? @$rv : $rv;
}

sub new {
	my $pkg = shift;
	my $code = shift or croak "must supply code body";
	my $post = shift;

	my $self = bless {
		depends => [],
		code => $code,
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

	my $sub = $self->code;
	$self->$sub(@_) unless $action_method eq "finish";

	my $rv = $self->action->$action_method(@_);

	if ($action_method ne "start" and my $post = $self->post){
		$self->$post(@_);
	}

	$rv;
}

sub step ($&;&) {
	my $action_class = shift;

	my $step = Step::Closure->new(@_);

	$action_class->require
		or die "Couldn't require $action_class: $UNIVERSAL::require::ERROR";
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
