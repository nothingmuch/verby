#!/usr/bin/perl

package EERS::Installer::Dispatch;
use base qw/Class::Accessor/;

use strict;
use warnings;

use Algorithm::Dependency::Ordered;
use List::MoreUtils qw/all/;
use Carp qw/croak/;

__PACKAGE__->mk_accessors(qw/step_source dep_resolver/); 

sub new {
	my $pkg = shift;
	my $src = shift;

	my $self = bless { }, $pkg;
	
	$self->step_source($src);
	$self->dep_resolver(
		Algorithm::Dependency::Ordered->new(
			source => $src,
			selected => [ map { $_->id } $self->satisfied_steps ],
		) || die "couldn't create dependency resolver",
	);

	$self;
}

my %vclasses = (
	step_source => "Algorithm::Dependency::Source",
	dep_resolver => "Algorithm::Dependency::Ordered",
);
sub set {
	my $self = shift;
	my $key = shift;
	my $value = shift;

	croak "$value is not a $vclasses{$key}" unless $value->isa($vclasses{$key});

	$self->SUPER::set($key, $value);
}

sub pending_steps {
	my $self = shift;
	@{ $self->{pending} || $self->_seed_pending_steps };
}

sub _seed_pending_steps {
	my $self = shift;

	$self->{pending} = [
		map { $self->step_source->item($_) }
			@{ $self->dep_resolver->schedule_all || die "couldn't schedule dependencies" }
	];
	# FIXME discard dep_resolver?
}

sub satisfied_steps {
	my $self = shift;
	values %{ $self->{satisfied} ||= {
			map { $_->id => $_ }
				grep { $_->satisfied }
					$self->step_source->items
		}
	}
}

sub is_satisfied {
	my $self = shift;
	my $step = shift;

	exists $self->{satisfied}{$step->id};
}

sub mark_satisfied {
	my $self = shift;
	my $step = shift;

	$self->{satisfied}{$step->id} = $step;
}

sub dispatch {
	my $self = shift;

	while ($self->pending_steps){
		my $step = $self->pick_next_step;
		$self->start_step($step);
	}

	$self->wait_all;
}

sub pick_next_step {
	my $self = shift;

	# TODO
	# push into the ready list as long as (shift @pending) is doesn't depend on anyone (need $dep for this)
	# pick first from ready list with this priority scheme:
	#     ->can("start")
	#     number of dependant

	# FIXME async jobs must be finished if $pending[0] depends on anyone

	shift @{ $self->{pending} };
}

sub start_step {
	my $self = shift;
	my $step = shift;
	
	# FIXME should be able to place a limit on the @running queue, akin to make -j N

	if ($step->can("start") and $step->can("finish")){
		$step->start;
		push @{ $self->{running} }, $step;
		$self->wait_all; # FIXME this should be removed when async job deps are implemented
	} else {
		$step->execute;
		$self->mark_satisfied($step);
	}
}

sub wait_all {
	my $self = shift;
	# finish all running tasks
	while (@{ $self->{running} ||= [] }){
		my $step = shift @{ $self->{running} };
		$step->finish;
		$self->mark_satisfied($step);
	}
}

__PACKAGE__

__END__

=pod

=head1 NAME

EERS::Installer::Dispatch - The step dispatch and dependancy resolution
module.

=head1 SYNOPSIS

	use EERS::Installer::Dispatch;

=head1 DESCRIPTION

This object dispatches installer steps based on their interdependencies. It
receives an object that isa L<Algorithm::Dependency::Source>, which should
return step objects.

=head1 METHODS

=over 4

=item new $src

This constructor accepts a step source as it's only parameter.

=item dispatch

Execute all unsatisfied steps.

=item wait_all

C<finish> all running steps.

=item pick_next_step

Returns the next step that should be executed, and removes it from the pending
list.

=item start_step $step

Invokes $step's execution methods.

=item pending_steps

Returns a list of steps that need to be executed.

=item mark_satisfied $step

Remember that $step is satisfied.

=item is_satisfied $step

Whether $step is cached as satisfied (not the same as C<< $step->satisfied >>)

=item satisfied_steps

Returns a list of step objects that have already been executed, or didn't need
to be in the first place.

=item step_source

This is a L<Class::Accessor> method. Additional isa checking is performed to
make sure the source is an L<Algorithm::Dependency::Source>.

=item dep_resolver

Same as C<step_source>, but isa L<Algorithm::Dependency::Ordered>.

=item set

Overrides L<Class::Accessor/set> to perform some isa checking.

=back

=head1 PARALLEL DISPATCH

This is not yet implemented.

=cut
