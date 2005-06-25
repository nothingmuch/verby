#!/usr/bin/perl

package Action::Mysql::CreateTable::Hewitt;
use base qw/Action::Mysql::CreateTable/;

use strict;
use warnings;

sub do {
	my $self = shift;
	my $c = shift;;

	$c->schema(q{
		question_id MEDIUMINT UNSIGNED, 
		scoretype_id TINYINT UNSIGNED,
		score TINYINT UNSIGNED
	});
	
	$self->SUPER::do($c);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::Mysql::CreateTable::Hewitt - 

=head1 SYNOPSIS

	use Action::Mysql::CreateTable::Hewitt;

=head1 DESCRIPTION

=cut
