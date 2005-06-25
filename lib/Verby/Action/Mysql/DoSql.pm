#!/usr/bin/perl

package Verby::Action::Mysql::DoSql;
use base qw/Verby::Action/;

use strict;
use warnings;

sub do {
	my $self = shift;
	my $c = shift;

	my $dbh = $c->dbh;

	local $dbh->{PrintError} = 0;
	local $dbh->{RaiseError} = 0;
	local $dbh->{HandleError} = sub { $c->logger->logdie(shift(@_) . " $self " . Data::Dumper::Dumper($c->data)) };

	$self->do_sql($c);

	$self->confirm($c);
}

sub do_sql {
	my $self = shift;
	my $c = shift;

	my $dbh = $c->dbh;
	my $sql = $c->sql;

	$dbh->do($sql);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Mysql::DoSql - 

=head1 SYNOPSIS

	use Verby::Action::Mysql::DoSql;

=head1 DESCRIPTION

=cut
