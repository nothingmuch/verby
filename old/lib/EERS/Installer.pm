#!/usr/bin/perl

package EERS::Installer;

use strict;
use warnings;

__PACKAGE__

__END__

=pod

=head1 NAME

EERS::Installer - 

=head1 SYNOPSIS

	use EERS::Installer;

=head1 DESCRIPTION

=head1 PRIORITIES

These are Yuval's opinions on the priorities of the installer:

=over 4

=item 1

Correctness -  The installer must not allow itself to put the environment in
an inconsistent state without raising an internal error.

=item 2

Robustness - The installer must raise as few errors as possible, being able to
adapt more easily to it's environment, while retaining correctness.

=item 3

Performance - The installer ought to be quick, because it's replacing manual
labour.

This does not look like an issue that will be hard to solve.

=back

=head1 GUIDELINES

To achieve these priorities, a few guidelines may be set:

=over 4

=item Errors are thrown liberally

This ensures correctness by making sure we stop to think what's gone wrong.

=item Errors are cought liberally

This raises robustness, while not diminishing correctness. Instead of ignoring
errors to increase the survivability of the installer, we are forced to deal
with them. If we do deal with them, survivability is achieved in the correct
way.

=item Actions should strive for transactional behavior

Any action that technically can do so must be atomic.

Any action that cannot be atomic due to technical constraints must use standard
locking mechanisms, and know how to cleanup failed instances that ran before
it.

=item KISS

Tasks are broken down based on logical simplicity.

Instead of sprinkling complexity all around, the steps are simplified, while
the core is made complex. Although it probably will be quite complicated, on
the whole we are moving this complexity from N space into constant space, which
is more manageble and readable.

It is notable that the core is made of more pure (side-effect free) logic, more
than actions, so bugs are likely non-critical, and will hinder robustness, not
correctness.

The inherently more dangerous installation steps, OTOH, should be kept as
concise and clear as possible, to allow correct maintaince.

Simplest of all is the interface between these two parts. This ensures that
complexity cannot be imposed on the steps, by the complexity of the core

A benefit of KISS is that it composes better, allowing us, for example, to
parrallelize steps without raising step complexity, to achieve better
performance.

=back

=cut
