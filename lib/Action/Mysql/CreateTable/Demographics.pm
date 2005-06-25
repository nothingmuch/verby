#!/usr/bin/perl

package Action::Mysql::CreateTable::Demographics;
use base qw/Action::Mysql::CreateTable/;

use strict;
use warnings;

sub do {
	my $self = shift;
	my $c = shift;

	$c->schema(q{
		id INTEGER PRIMARY KEY,
		description VARCHAR(255)
	});

	$self->SUPER::do($c);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::Mysql::CreateTable::Demographics - 

=head1 SYNOPSIS

	use Action::Mysql::CreateTable::Demographics;

=head1 DESCRIPTION

=cut
