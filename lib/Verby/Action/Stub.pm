#!/usr/bin/perl

package Verby::Action::Stub;
use base qw/Verby::Action/;

use strict;
use warnings;

our $VERSION = '0.01';

sub do {
	$_[1]->logger->debug("stub do");
}

sub verify {
	$_[1]->logger->debug("stub verify");
	undef;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::Stub - An action which just logs debug messages instead of dying.

=head1 SYNOPSIS

	use Verby::Step::Closure qw/step/;

	my $s = step "Verby::Action::Stub";

=head1 DESCRIPTION

This action is good for use when you need to Stub certain actions.

=head1 METHODS 

=over 4

=item B<do>

=item B<verify>

=back

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
