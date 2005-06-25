#!/usr/bin/perl

package Step::CreateDB;
use base qw/Action::MysqlCreateDB/;

use strict;
use warnings;

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

Step::CreateDB - 

=head1 SYNOPSIS

	use Step::CreateDB;

=head1 DESCRIPTION

=cut
