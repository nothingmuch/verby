#!/usr/bin/perl

package Verby::Config::Source;
use base qw/Verby::Config::Data/;

use strict;
use warnings;

our $VERSION = '0.01';

use Tie::Memoize;

sub new {
	my $pkg = shift;

	my $self;
	tie my %data, 'Tie::Memoize', sub { $self->get_key(shift) };

	$self = bless { data => \%data }, $pkg;
}

sub get_key {
	die "subclass should extract keys from real config source";
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Config::Source - 

=head1 SYNOPSIS

	use Verby::Config::Source;

=head1 DESCRIPTION

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
