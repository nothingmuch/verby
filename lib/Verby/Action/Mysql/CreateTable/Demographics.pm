#!/usr/bin/perl

package Verby::Action::Mysql::CreateTable::Demographics;
use base qw/Verby::Action::Mysql::CreateTable/;

use strict;
use warnings;

sub do {
	my $self = shift;
	my $c = shift;
	
	my $id_column = $c->id_column;
	
	$c->schema(qq{
		$id_column INTEGER PRIMARY KEY,
		description VARCHAR(255)
	});

	$self->SUPER::do($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

	my $table_name = $c->table;
	(my $id_column = $table_name . "_id") =~ s/^(lkup|tbl)_//;
	$c->id_column($id_column);

	$self->SUPER::verify($c);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Mysql::CreateTable::Demographics - 

=head1 SYNOPSIS

	use Verby::Action::Mysql::CreateTable::Demographics;

=head1 DESCRIPTION

=cut
