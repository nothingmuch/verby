#!/usr/bin/perl

package Verby::Action::Mysql::CreateDB;
use Moose;

extends qw/Verby::Action::Mysql::DoSql/;

before do => sub {
	my ( $self, $c ) = @_;

	$c->sql("create database ?");
	$c->params([ undef, $c->db_name ]);

	my $dbh = $c->dbh;
	$c->logger->info("creating database in $dbh");
};

sub verify {
	my ( $self, $c ) = @_;

	exists $self->databases($c)->{$c->db_name}
}

sub databases {
	my ( $self, $c ) = @_;

	# returns a hash ref like { test => "dbi:mysql:test" }
	return { map { (DBI->parse_dsn($_))[4] => $_ } $c->dbh->data_sources };
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
