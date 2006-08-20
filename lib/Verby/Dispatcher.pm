#!/usr/bin/perl

package Verby::Dispatcher;
use Moose;


# FIXME
# do_all and wait_specific could be optimized to be a little less O(N) ish.
# with small data sets it doesn't really matter.

use Algorithm::Dependency::Objects::Ordered;
use Set::Object;
use Verby::Context;
use Carp qw/croak/;
use Tie::RefHash;

use POE;

require overload;

has step_set => (
	isa => "Set::Object",
	is	=> "ro",
	default => sub { Set::Object->new },
);

has satisfied_set => (
	isa => "Set::Object",
	is	=> "ro",
	default => sub { Set::Object->new },
);

has cxt_of_step => (
	isa => "HashRef",
	is	=> "ro",
	default => sub {
		tie my %cxt_of_step, "Tie::RefHash";
		return \%cxt_of_step;
	},
);

has derivable_cxts => (
	isa => "HashRef",
	is	=> "ro",
	default => sub {
	tie my %derivable_cxts, "Tie::RefHash";
		return \%derivable_cxts;
	},
);

has config_hub => (
	isa => "Object",
	is	=> "rw",
);

has global_context => (
	isa => "Object",
	is	=> "ro",
	lazy	=> 1,
	default => sub { $_[0]->config_hub->derive("Verby::Context") },
);

sub add_step {
	my $self = shift;

	my $steps = $self->step_set;

	foreach my $step (@_) {
		next if $steps->includes($step);

		$self->add_step($step->depends);

		(my $logger = $self->global_context->logger)->debug("adding step $step");
		$steps->insert($step);
	}
}

sub add_steps {
	my $self = shift;
	$self->add_step(@_);
}

sub get_cxt {
	my $self = shift;
	my $step = shift;

	$self->cxt_of_step->{$step} ||= Verby::Context->new($self->get_derivable_cxts($step));
}

sub get_derivable_cxts {
	my $self = shift;
	my $step = shift;

	@{ $self->derivable_cxts->{$step} ||= (
		$step->provides_cxt
			? [ Verby::Context->new($self->get_parent_cxts($step)) ]
			: [ $self->get_parent_cxts($step) ]
	)};
}

sub get_parent_cxts {
	my $self = shift;
	my $step = shift;

	return $self->global_context unless @{ $step->depends };
	map { $self->get_derivable_cxts($_) } $step->depends;
}

sub create_poe_sessions {
	my ( $self ) = @_;

	my $all_steps = $self->step_set;
	my $satisfied = $self->satisfied_set;

	my $pending = $all_steps->difference( $satisfied );

	my @sessions;

	foreach my $step ( $pending->members ) {
		push @sessions, POE::Session->create(
			inline_states => {
				_start => sub {
					my ( $kernel, $session) = @_[KERNEL, SESSION];
					#warn "_start handler";
					$kernel->sig("VERBY_STEP_FINISHED" => "step_finished");
					$kernel->refcount_increment( $session->ID, "step_unexecuted" );
					$kernel->yield("try_executing_step");
				},
				step_finished => sub {
					my ( $kernel, $heap, $done ) = @_[KERNEL, HEAP, ARG0];
					#warn "some step finished: $done";

					my $deps = $heap->{dependencies};

					if ( $deps->includes($done) ) {
						#warn "$done has finished, affecting $heap->{step}";
						$deps->remove( $done );
						$kernel->yield("try_executing_step");
					}
				},
				try_executing_step => sub {
					my ( $kernel, $session, $heap ) = @_[KERNEL, SESSION, HEAP];

					return if $heap->{dependencies}->size; # don't run if we're waiting
					return if $heap->{ran}++; # don't run twice

					$kernel->sig("VERBY_STEP_FINISHED"); # we're no longer waiting for other steps to finish
					$kernel->refcount_decrement( $session->ID, "step_unexecuted" ); # this session can go away afterwords
					@sessions = grep { $_ != $session } @sessions;
					#warn "remaining sessions: @sessions";

					#warn "staring $heap->{step}";
					$heap->{verby_dispatcher}->start_step( $heap->{step}, \@_ );
				},
				_stop => sub {
					my ( $kernel, $heap ) = @_[KERNEL, HEAP];
					my $step = $heap->{step};
					#warn "finished $step";

					$heap->{satisfied}->insert($step);

					$_->() for @{ $heap->{post_hooks} };

					#warn "signaling all sessions: @sessions";
					$kernel->call( $_, "step_finished", $step ) for @sessions;
				},
			},
			heap => {
				step             => $step,
				dependencies     => Set::Object->new( $step->depends )->difference($satisfied),
				ran              => 0,
				verby_dispatcher => $self,
				satisfied        => $satisfied,
				post_hooks       => [],
			},
		);
	}
}

sub do_all {
	my $self = shift;
	$self->create_poe_sessions;
	$poe_kernel->run;
}

sub start_step {
	my ( $self, $step, $poe ) = @_;

	my $g_cxt = $self->global_context;
	my $cxt = $self->get_cxt($step);

	if ($step->is_satisfied($cxt)){
		$g_cxt->logger->debug("step $step has been satisfied while it was waiting. Skipped.");
		return;
	}

	$g_cxt->logger->debug("starting step $step");
	$step->do($cxt, $poe);
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

sub finish_step {
	# FIXME.... Technical debt!
	die "Can't finish an unstarted step... the universe is bending!";
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

None that we are aware of. Of course, if you find a bug, let us know, and we
will be sure to fix it.

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to
COVERAGE section of the L<Verby> module for more information.

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
