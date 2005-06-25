#!/usr/bin/perl

package Action::Mysql::CreateTable;
use base qw/Action::Mysql::DoSql/;

use strict;
use warnings;

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

	# maybe check that the schema is actually OK?
	return (Mysql::Table::MetaData->new($c->dbh)->get_info($c->table) ? 1 : undef);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::Mysql::CreateTable - 

=head1 SYNOPSIS

	use Action::Mysql::CreateTable;

=head1 DESCRIPTION

=cut
