#!/usr/bin/perl

package Dispatcher;

use strict;
use warnings;

use Algorithm::Dependency::Objects::Ordered;
use Set::Object;
use Context;
use Carp qw/croak/;

sub new {
	my $pkg = shift;
	bless {
		step_set      => Set::Object->new,
		running_set   => Set::Object->new,
		satisfied_set => Set::Object->new,
		running_queue => [],
		config_hub    => undef
	}, $pkg;
}

sub step_set      { (shift)->{step_set}      }
sub running_set   { (shift)->{running_set}   }
sub satisfied_set { (shift)->{satisfied_set} }

sub config_hub {
    my $self = shift;
    $self->{config_hub} = shift if @_;
    $self->{config_hub};
}

sub add_step {
	my $self = shift;
	my $step = shift;

	my $steps = $self->step_set;
	my $satisfied = $self->satisfied_set;

	return if $steps->includes($step);

	$self->add_step($_) for $step->depends;

	(my $logger = $self->global_context->logger)->debug("adding step $step");
	$steps->insert($step);

	my $context = $self->global_context->derive("Context");

	if ($step->is_satisfied($context)) {
		$logger->debug("step is already satisfied");
		$satisfied->insert($step);
	}
}

sub global_context {
	my $self = shift;
	$self->{global_context} ||= $self->config_hub->derive("Context");
}

sub do_all {
	my $self = shift;

	my $global_context = $self->global_context;

	foreach my $step ($self->ordered_steps){
		$self->start_step($step);
	}

	$self->wait_all;
}

sub ordered_steps {
	my $self = shift;
	$self->mk_dep_engine->schedule_all;
}

sub mk_dep_engine {
	my $self = shift;

	$self->dep_engine_class->new(
		objects => $self->step_set,
		selected => $self->satisfied_set,
	);
}

sub dep_engine_class {
	"Algorithm::Dependency::Objects::Ordered";
}

sub start_step {
	my $self = shift;
	my $step = shift;

	# FIXME should be able to place a limit on the running set, akin to make -j N
	$self->wait_all;

	my $g_cxt = $self->global_context;
	my $new_cxt = $g_cxt->derive;
	
	if ($step->is_satisfied($new_cxt)){
		$g_cxt->logger->debug("step $step has been satisfied while it was waiting. Skipped.");
		$self->satisfied_set->insert($step);
		return;
	}

	$g_cxt->logger->debug("starting step $step");
	
	if ($step->can("start") and $step->can("finish")){
		$g_cxt->logger->debug("$step is async");
		$step->start($new_cxt);
		$self->mark_running($step, $new_cxt)
	} else {
		$g_cxt->logger->debug("$step is sync");
		$step->do($new_cxt);
		$self->satisfied_set->insert($step);
	}
}

sub wait_all {
	my $self = shift;
	# finish all running tasks

	$self->global_context->logger->debug("waiting for all running steps");

	my $satisfied = $self->satisfied_set;
	
	while ($self->running_steps){
		my $entry = $self->pop_running;
		my ($step, $cxt) = @$entry;
		$step->finish($cxt);
		$satisfied->insert($step);
	}
}

sub _set_members_query {
	my $self = shift;
	my $set = shift;
	return wantarray ? $set->members : $set->size;
}

sub steps {
	my $self = shift;
	$self->_set_members_query($self->step_set);
}

sub running_steps {
	my $self = shift;
	$self->_set_members_query($self->running_set);
}

sub mark_running {
	my $self = shift;
	my $step = shift;
	my $cxt = shift;
	$self->running_set->insert($step);
	$self->push_running_queue([$step, $cxt]);
}

sub is_running {
	my $self = shift;
	my $step = shift;
	$self->running_set->includes($step);
}

sub pop_running {
	my $self = shift;
	my $step = shift;
	my $cxt = shift;
	my $entry = $self->pop_running_queue;
	$self->running_set->remove($entry->[0]);
	return $entry;
}

sub push_running_queue {
	my $self = shift;
	push @{ $self->{running_qeue} }, @_;
}

sub pop_running_queue {
	my $self = shift;
	shift @{ $self->{running_qeue} };
}

sub is_satisfied {
	my $self = shift;
	my $step = shift;

	croak "$step is not registered at all"
		unless $self->step_set->contains($step);

	$self->satisfied_set->contains($step);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Dispatcher - 

=head1 SYNOPSIS

	use Dispatcher;

=head1 DESCRIPTION

=cut
