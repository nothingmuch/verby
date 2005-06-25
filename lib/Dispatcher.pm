#!/usr/bin/perl

package Dispatcher;

use strict;
use warnings;

use Algorithm::Dependency::Objects::Ordered;
use Set::Object;
use Context;
use Carp qw/croak/;
use Tie::RefHash;

sub new {
	my $pkg = shift;
	tie my %cxt_of_step, "Tie::RefHash";
	tie my %derivable_cxts, "Tie::RefHash";
	bless {
		step_set       => Set::Object->new,
		running_set    => Set::Object->new,
		satisfied_set  => Set::Object->new,
		cxt_of_step    => \%cxt_of_step,
		derivable_cxts => \%derivable_cxts,
		running_queue  => [],
		config_hub     => undef
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

	my $context = $self->get_cxt($step);

	if ($step->is_satisfied($context)) {
		$logger->debug("Step '$step' is already satisfied");
		$satisfied->insert($step);
	}
}

sub global_context {
	my $self = shift;
	$self->{global_context} ||= $self->config_hub->derive("Context");
}

sub get_cxt {
	my $self = shift;
	my $step = shift;

	$self->{cxt_of_step}{$step} ||= Context->new($self->get_derivable_cxts($step));
}

sub get_derivable_cxts {
	my $self = shift;
	my $step = shift;

	@{ $self->{derivable_cxts}{$step} ||= (
		$step->provides_cxt
			? [ Context->new($self->get_parent_cxts($step)) ]
			: [ $self->get_parent_cxts($step) ]
	)};
}

sub get_parent_cxts {
	my $self = shift;
	my $step = shift;

	return $self->global_context unless $step->depends;
	map { $self->get_derivable_cxts($_) } $step->depends;
}

sub do_all {
	my $self = shift;

	my $global_context = $self->global_context;

	my @free_steps;
	my @steps = map { [ $_, Set::Object->new($_->depends) ] } $self->ordered_steps;

	my $satisfied = $self->satisfied_set;

	while (@steps){
		$self->pump_running;

		push @free_steps, shift(@steps)->[0] while (@steps and $steps[0][1]->subset($satisfied));
		@free_steps = sort { $a->can("start") ? ($b->can("start") ? 0 : -1) : 1 } @free_steps;
		
		if (@free_steps){
			$self->start_step(shift @free_steps);
		} else {
			$self->global_context->logger->debug("free step pool exhausted");
			$self->wait_one;
		}
	}

	$self->wait_all;
}

sub ordered_steps {
	my $self = shift;
	my @steps = $self->mk_dep_engine->schedule_all;
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

	my $g_cxt = $self->global_context;

	my $cxt = $self->get_cxt($step);
	
	if ($step->is_satisfied($cxt)){
		$g_cxt->logger->debug("step $step has been satisfied while it was waiting. Skipped.");
		$self->satisfied_set->insert($step);
		return;
	}

	$g_cxt->logger->debug("starting step $step");
	
	if ($step->can("start") and $step->can("finish")){
		$g_cxt->logger->debug("$step is async");
		$step->start($cxt);
		$self->mark_running($step, $cxt)
	} else {
		$g_cxt->logger->debug("$step is sync");
		$step->do($cxt);
		$self->satisfied_set->insert($step);
	}
}

sub pump_running {
	my $self = shift;

	foreach my $entry (@{ $self->{running_queue} }){
		my ($step, $cxt) = @$entry;
		next unless $step->can("pump");
		
		unless ($step->pump($cxt)){
			$self->global_context->logger->debug("step '$step' has finished");
			$self->wait_specific($entry);
		}
	}
}

sub wait_all {
	my $self = shift;
	# finish all running tasks

	$self->global_context->logger->debug("waiting for all running steps");
	
	while ($self->running_steps){
		$self->wait_one;
	}
}

sub wait_one {
	my $self = shift;

	my $entry = $self->pop_running || return;
	my ($step, $cxt) = @$entry;
	$self->global_context->logger->debug("waiting for step '$step'");

	$self->finish_step($step, $cxt);
}

sub wait_specific {
	my $self = shift;

	my $entry = shift;

	my ($step, $cxt) = @$entry;
	@{ $self->{running_queue} } = grep { $_ != $entry } @{ $self->{running_queue} };

	$self->finish_step($step, $cxt);
}

sub finish_step {
	my $self = shift;
	my $step = shift;
	my $cxt = shift;

	$step->finish($cxt);
	$self->satisfied_set->insert($step);
	$self->running_set->remove($step);
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
	my $entry = $self->pop_running_queue || return;
	return $entry;
}

sub push_running_queue {
	my $self = shift;
	push @{ $self->{running_queue} }, @_;
}

sub pop_running_queue {
	my $self = shift;
	shift @{ $self->{running_queue} };
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
