#!/usr/bin/perl

package Verby::Action;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw/longmess/;

sub new {
	my $pkg = shift;
	bless {}, $pkg;
}

sub do {
	die "do(@_) not implemented" . longmess;
}

sub verify {
	die "verify(@_) not implemented" . longmess;
}

sub confirm {
	my $self = shift;
	my $cxt = shift;
	$self->verify($cxt, @_) or
		$cxt->logger->logdie(
			"verification of $self failed: "
			. ($cxt->error || "error unknown"));
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action - The baseclass for an action in Verby.

=head1 SYNOPSIS

	use base qw/Verby::Action/;
	sub do { ... }
	sub confirm { ... }

=head1 DESCRIPTION

A Verby::Action is basically a reusable bit of code.

Assuming it gets a L<Verby::Context> object sent to both C<do> and C<verify>,
it knows to check whether it needs to be done, and actually do the job.

Think of it as an abstraction of a make target.

=head1 METHODS

=over 4

=item B<new>

=item B<do $cxt>

The thing that the action really does. For example

	package Verby::Action::Download;

	sub do {
		my ($self, $c) = @_;
		system("wget", "-O", $c->file, $c->url);
	}

Will use wget to download C<< $c->url >> to C<< $c->file >>.

This is a bad example though, you ought to subclass L<Verby::Action::RunCmd> if
you want to run a command.

=item B<verify $cxt>

Perform a boolean check - whether or not the action needs to happen or not.

For example, if C<do> downloads C<< $c->file >> from C<< $c->url >>, then the
verify method would look like:

	sub verify {
		my ($self, $c) = @_;
		-f $c->file;
	}

=item B<confirm $cxt>

Typically called at the end of an action's do:

	sub do {
		my ($self, $c) = @_;
		...
		$self->confirm($c);
	}

It will call C<< $c->logger->logdie >> unless C<verify> returns a true value.

=back

=head1 ASYNCHRONEOUS INTERFACE

An asynchroneous action typically implements two or three methods instead of
C<do>, analogeous to C<IPC::Run>'s nonblocking interface:

=over 4

=item B<start $cxt>

Initiate the action, returning as early as possible.

=item B<finish $cxt>

Clean up the action.

=item B<pump $cxt>

Perform any nonblocking operation needed to keep things moving.

If this retrurns a false value, the action is considered finished, and
C<finish> will be called by the C<Verby::Dispatcher>.

=back

Note that this documentation assumes delegation of step methods to action
methods.

L<Verby::Dispatcher> actually has nothing to do with L<Verby::Action>, it's
just that typically a L<Verby::Step> is just a thin wrapper for
L<Verby::Action>, so the methods roughly correspond.

See L<Verby::Step::Closure> for a trivial way to generate steps given a
L<Verby::Action> subclass.

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
