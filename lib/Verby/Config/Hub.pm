#!/usr/bin/perl

package Verby::Config::Hub;
use Module::Pluggable (
	sub_name => "sources",
	search_path => ["Verby::Config::Source"],
	instantiate => "new",
);

use strict;
use warnings;

our $VERSION = '0.01';

sub new {
	my $pkg = shift;

	tie my %data, 'Tie::HashDefaults', map { $_->data } my @sources = $pkg->sources;
	bless {
		sources => \@sources,
		data => \%data,
	}, $pkg;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Config::Hub - 

=head1 SYNOPSIS

	use Verby::Config::Hub;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

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
