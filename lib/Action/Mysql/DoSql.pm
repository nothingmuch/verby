#!/usr/bin/perl

package Action::Mysql::DoSql;
use base qw/Action/;

use strict;
use warnings;

sub do {
	my $self = shift;
	my $c = shift;

	my $dbh = $c->dbh;

	local $dbh->{PrintError} = 0;
	local $dbh->{RaiseError} = 0;
	local $dbh->{HandleError} = sub { $c->logger->logdie(shift) };

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

Action::Mysql::DoSql - 

=head1 SYNOPSIS

	use Action::Mysql::DoSql;

=head1 DESCRIPTION

=cut
