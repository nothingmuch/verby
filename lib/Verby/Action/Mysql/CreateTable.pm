#!/usr/bin/perl

package Verby::Action::Mysql::CreateTable;
use base qw/Verby::Action::Mysql::DoSql/;

use strict;
use warnings;

our $VERSION = '0.01';

use Verby::Action::Mysql::Util;

sub do_sql {
	my $self = shift;
	my $c = shift;

	my $table = $c->table;
	my $schema = $c->schema;

	$c->sql(qq{
		CREATE TABLE $table (
			$schema
		);
	});

	$c->logger->info("creating table '$table'");

	$self->SUPER::do_sql($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

	my $table_name = $c->table;

	my $table_info = Verby::Action::Mysql::Util->new($c->dbh)->get_info($table_name);
	$c->logger->debug("table info query on '$table_name' yields " . ($table_info ? "true" : "false"));
	
	return ($table_info ? 1 : undef);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Mysql::CreateTable - Action to create a table inside a MySQL database

=head1 SYNOPSIS

	use Verby::Action::Mysql::CreateTable;

=head1 DESCRIPTION

This action, given a table name and a table definition, will create the table in a MySQL database.

=head1 METHODS 

=over 4

=item B<do_sql>

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
