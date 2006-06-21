#!/usr/bin/perl

package Verby::Action::Mysql::CreateDB;
use base qw/Verby::Action/;

use strict;
use warnings;

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

Verby::Action::Mysql::CreateDB - 

=head1 SYNOPSIS

	use Verby::Action::Mysql::CreateDB;

=head1 DESCRIPTION

=cut
