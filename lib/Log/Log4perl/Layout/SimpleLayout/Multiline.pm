#!/usr/bin/perl

package Log::Log4perl::Layout::SimpleLayout::Multiline;
use base qw/Log::Log4perl::Layout::SimpleLayout/;

use strict;
use warnings;

our $VERSION = '0.01';

sub render {
	my $self = shift;
	my $output = $self->SUPER::render(@_);

	$output =~ /([A-Z]+ - )/;

	my $spaces = ' ' x length($1);
	$output =~ s/(\r?\n|\r)(?!$)/$1$spaces\t/g;

	$output;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Log::Log4perl::Layout::SimpleLayout::Multiline - 

=head1 SYNOPSIS

	use Log::Log4perl::Layout::SimpleLayout::Multiline;

=head1 DESCRIPTION

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
