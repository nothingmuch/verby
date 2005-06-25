#!/usr/bin/perl

package Verby::Action::MkPath;
use base qw/Verby::Action/;

use strict;
use warnings;

our $VERSION = '0.01';

use File::Path qw/mkpath/;

sub do {
	my $self = shift;
	my $c = shift;

	my $path = $c->path;

	$c->logger->info("creating path '$path'");
	mkpath($path)
		or $c->logger->logdie("couldn't mkpath('$path'): $!");

	$self->confirm($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

	-d $c->path;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::MkPath - 

=head1 SYNOPSIS

	use Verby::Action::MkPath;

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
