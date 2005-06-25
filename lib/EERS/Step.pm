#!/usr/bin/perl

package EERS::Step;
use base qw/Algorithm::Dependency::Item/;

use strict;
use warnings;

use UNIVERSAL::moniker;

sub depends { qw// }

sub id {
	my $self = shift;
	if ($self->isa("Class::StrongSingleton") or $self->isa("Class::Singleton")){
		# if the class is a singleton, it can be referred by it's moniker
		return $self->moniker;
	} else {
		die "This method must be implemented by non singleton subclasses";
	}
}

sub execute { die "This method must be implemented by a subclass" }

sub satisfied { undef }

# start and finish are not stubbed, because they are optional

__PACKAGE__

__END__

=pod

=head1 NAME

EERS::Step - The base class for installation steps.

=head1 SYNOPSIS

	use base qw/EERS::Step/;

=head1 DESCRIPTION

This class's heirs represent single nodes in the dependancy tree of the
installation.

For example, in order for <project>/conf/* files to be created, the /var/www
directories must be ready.

The step which templates httpd.conf thus depends on /var/www/<project> being
created.

Steps are broken down to ease their creation, into medium sized logical units.

Each step has a boolean check to tell if it's C<satisfied>. If it has not, it's
C<execute> method is called, and unless the code C<die>s the step is assumed to
be satisfied.

Steps are encouraged to C<< die unless $self->satisfied >> at the end of
C<execute>, if the check is cheap.

Dependancies are resolved by checking 

=head1 ASYNCHRONEOUS INTERFACE

To allow parrallelization of non-competing tasks each step that offers the
C<start> and C<finish> methods can implement them instead of C<execute>.

C<start> will be called as early as possible, and is allowed to query the user
for options. It should return within a reasonable time.

C<finish> is a blocking call, and should be called as late as possible.

=head1 Algorithm::Dependency

This class subclasses L<Algorithm::Dependency::Item>. Dependencies are resolved
using L<Algorithm::Dependency::Ordered> by L<EERS::Installer>.

=head1 METHODS

=over 4

=item id

See L<Algorithm::Dependency::Item/id>.

For singleton classes, the default id is L<UNIVERSAL::moniker>.

=item depends

See L<Algorithm::Dependency::Item/depends>.

=back

=item satisfied

True if this step can be skipped.

=item execute

Perform the step.

=item start

Alternative to L<execute>, useful for example, for checking out svn repos in
the background.

=item finish

Waits until the step has finished, so that depended upon steps can be executed.

=cut
