#!/usr/bin/perl

package Action::Mysql::CreateTable;
use base qw/Action/;

use strict;
use warnings;

sub do {
	my $self = shift;
	my $c = shift;

	my $dbh = $c->dbh;
	my $table = $c->table;
	my $schema = $c->schema;

	local $dbh->{PrintError} = 0;
	local $dbh->{RaiseError} = 0;
	local $dbh->{HandleError} = sub {
		my $msg = shift;
		$c->logger->logdie($msg);
	};

	my $sql = qq{
		CREATE TABLE $table (
			$schema
		);
	};

	$c->logger->info("creating table '$table'");
	
	$dbh->do($sql);

	$self->confirm($c);
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
