#!/usr/bin/perl

package Verby::Action::Mysql::CreateTable;
use base qw/Verby::Action::Mysql::DoSql/;

use strict;
use warnings;

use Mysql::Table::MetaData;

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

	my $table_info = Mysql::Table::MetaData->new($c->dbh)->get_info($table_name);
	$c->logger->debug("table info query on '$table_name' yields " . ($table_info ? "true" : "false"));
	
	return ($table_info ? 1 : undef);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Mysql::CreateTable - 

=head1 SYNOPSIS

	use Verby::Action::Mysql::CreateTable;

=head1 DESCRIPTION

=cut
