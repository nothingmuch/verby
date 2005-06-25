#!/usr/bin/perl

package Verby::Action::MysqlCreateDB;
use base qw/Verby::Action/;

use strict;
use warnings;

our $VERSION = '0.01';

use DBI;

sub do {
	my $self = shift;
	my $c = shift;

	my $dbh = $c->dbh;
	
	$c->logger->info("creating database in $dbh");

	{
		local $dbh->{RaiseError} = 1;
		local $dbh->{PrintError} = 0; # no need to print it if it's raised
		$dbh->do("create database ?", undef, $c->db_name);
	}

	$self->confirm($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

	exists $self->databases($c)->{$c->db_name}
}

sub databases {
	my $self = shift;
	my $c = shift;

	# returns a hash ref like { test => "dbi:mysql:test" }
	+{ map { (DBI->parse_dsn($_))[4] => $_ } $c->dbh->data_sources };
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::MysqlCreateDB - Action to create a database in MySQL

=head1 SYNOPSIS

	use Verby::Action::MysqlCreateDB;

=head1 DESCRIPTION

This Action, given a database name, will create said database in MySQL.

=head1 METHODS 

=over 4

=item B<do>

=item B<databases>

=item B<verfiy>

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
