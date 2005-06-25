#!/usr/bin/perl

package Verby::Step::CreateDB;
use base qw/Verby::Action::MysqlCreateDB/;

use strict;
use warnings;

our $VERSION = '0.01';

sub config {
	my $self = shift;
	my $c = shift;

	$c->dbh(DBI->connect("dbi:mysql:", %attrs));
	$c->db_name($client);
}

sub do {
	my $self = shift;
	my $c = shift;

	my $new = $c->derive;
	$self->SUPER::do($new);

	$new->export("dbh");
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Step::CreateDB - 

=head1 SYNOPSIS

	use Verby::Step::CreateDB;

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
