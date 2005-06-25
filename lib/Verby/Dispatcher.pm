#!/usr/bin/perl

package Verby::Dispatcher;

# FIXME
# do_all and wait_specific could be optimized to be a little less O(N) ish.
# with small data sets it doesn't really matter.

use strict;
use warnings;

use Algorithm::Dependency::Objects::Ordered;
use Set::Object;
use Verby::Context;
use Carp qw/croak/;
use Tie::RefHash;
require overload;

our $VERSION = 0.01;

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

	my $steps = $self->step_set;
	my $satisfied = $self->satisfied_set;

	foreach my $step (@_) {
		next if $steps->includes($step);

		$self->add_step($step->depends);

		(my $logger = $self->global_context->logger)->debug("adding step $step");
		$steps->insert($step);

		my $context = $self->get_cxt($step);

		if ($step->is_satisfied($context)) {
			$logger->debug("Step '$step' is already satisfied");
			$satisfied->insert($step);
		}
	}
}

sub add_steps {
	my $self = shift;
	$self->add_step(@_);
}

sub global_context {
	my $self = shift;
	$self->{global_context} ||= $self->config_hub->derive("Verby::Context");
}

sub get_cxt {
	my $self = shift;
	my $step = shift;

	$self->{cxt_of_step}{$step} ||= Verby::Context->new($self->get_derivable_cxts($step));
}

sub get_derivable_cxts {
	my $self = shift;
	my $step = shift;

	@{ $self->{derivable_cxts}{$step} ||= (
		$step->provides_cxt
			? [ Verby::Context->new($self->get_parent_cxts($step)) ]
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

	$self->start_step($_) for @free_steps;

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
		$self->mark_running($step)
	} else {
		$g_cxt->logger->debug("$step is sync");
		$step->do($cxt);
		$self->satisfied_set->insert($step);
	}
}

sub pump_running {
	my $self = shift;

	$self->global_context->logger->debug("pumping all running steps");

	foreach my $step (@{ $self->{running_queue} }){
		next unless $step->can("pump");
		
		unless ($step->pump($self->get_cxt($step))){
			$self->global_context->logger->debug("step '$step' has finished");
			$self->wait_specific($step);
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

	# TODO
	# in a subclass based around Event or POE make this sensitive to the watchers that actions hand out.
	my $step = $self->pop_running || return;
	$self->global_context->logger->debug("waiting for step '$step'");
	$self->finish_step($step);
}

sub wait_specific {
	my $self = shift;
	my $step = shift;

	@{ $self->{running_queue} } = grep { overload::StrVal($_) ne overload::StrVal($step) } @{ $self->{running_queue} };

	$self->finish_step($step);
}

sub finish_step {
	my $self = shift;
	my $step = shift;

	my $cxt = $self->get_cxt($step);

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
	$self->push_running($step);
}

sub is_running {
	my $self = shift;
	my $step = shift;
	$self->running_set->includes($step);
}

sub push_running {
	my $self = shift;
	push @{ $self->{running_queue} }, @_;
}

sub pop_running {
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

Verby::Dispatcher - Takes steps and executes them. Sort of like what make(1) is to a
Makefile.

=head1 SYNOPSIS

	use Verby::Dispatcher;
	use Verby::Config::Data; # or something equiv

	my $c = Verby::Config::Data->new(); # ... needs the "logger" field set

	my $d = Verby::Dispatcher->new;
	$d->config_hub($c);

	$d->add_steps(@steps);

	$d->do_all;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

Returns a new L<Verby::Dispatcher>. Duh!

=item B<add_steps *@steps>

=item B<add_step *@steps>

Add a number of steps into the dispatcher pool.

Anything returned from L<Verby::Step/depends> is aggregated recursively here, and
added into the batch too.

=item B<do_all>

Calculate all the dependencies using L<Algorithm::Dependency::Objects>, and
then dispatch in order.

=item B<dep_engine_class>

The class used to instantiate the dependecy resolver. Defaults to
L<Algorithm::Dependency::Objects::Ordered>. Subclass if you don't like it.

=item B<config_hub ?$new_config_hub>

A setter getter for the L<Verby::Config::Data> (or compatible) object from which we
will derive the global context, and it's sub-contexts.

=item B<global_context>

Returns the global context for the dispatcher.

If necessary derives a context from L</config_hub>.

=item B<is_running $step>

Whether or not $step is currently executing.

=item B<is_satisfied $step>

Whether or not $step does not need to be executed (because it was already
executed or because it didn't need to be in the first place).

=item B<get_cxt $step>

Returns the context associated with $step. This is where $step will write it's
data.

=item B<get_derivable_cxts $step>

Returns the contexts to derive from, when creating a context for $step.

If $step starts a new context (L<Step/provides_cxt> is true) then a new context
is created here, derived from get_parent_cxts($step). Otherwise it simply
returns get_parent_cxts($step).

Note that when a step 'provides a context' this really means that a new context
is created, and this context is derived for the step, and any step that depends
on it.

=item B<get_parent_cxts $step>

If $step depends on any other steps, take their contexts. Otherwise, returns
the global context.

=item B<start_step $step>

If step supports the async interface, start it and put it in the running step
queue. If it's synchroneous, call it's L<Step/do> method.

=item B<finish_step $step>

Finish step, and mark it as satisfied. Only makes sense for async steps.

=item B<mark_running $step>

Put $step in the running queue, and mark it in the running step set.

=item B<push_running $step>

Push $step into the running step queue.

=item B<pop_running>

Pop a step from the running queue.

=item B<mk_dep_engine>

Creates a new object using L</dep_engine_class>.

=item B<ordered_steps>

Returns the steps to be executed in order.

=item B<pump_running>

Give every running step a bit of time to move things forward.

This method is akin to L<IPC::Run/pump>.

It also calls L</finish_step> on each step that returns false.

=item B<steps>

Returns a list of steps that the dispatcher cares about.

=item B<step_set>

Returns the L<Set::Object> that is used for internal bookkeeping of the steps
involved.

=item B<running_steps>

Returns a list of steps currently running.

=item B<running_set>

Returns the L<Set::Object> that is used to track which steps are running.

=item B<satisfied_set>

Returns the L<Set::Object> that is used to track which steps are satisfied.

=item B<wait_all>

Wait for all the running steps to finish.

=item B<wait_one>

Effectively C<finish_step(pop_running)>.

=item B<wait_specific $step>

Waits for a specific step to finish. Called by L<pump_running> when a step
claims that it's ready.

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>
stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
