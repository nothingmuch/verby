#!/usr/bin/perl

package Action::Mysql::CreateTable::Results;
use base qw/Action::Mysql::CreateTable/;

use strict;
use warnings;

sub do {
	my $self = shift;
	my $c = shift;

	my $file = $c->file;
	my $fs = $c->field_sep;

	$c->skip_lines(1);

	open my $fh, "<", $file
		or $c->logger->logdie("couldn't open file '$file': $!");
	
	my @colnames = split(qr/\Q$fs/, do {local $/ = $c->line_sep; scalar <$fh> });
	
	$c->schema(join(",\n", map {
		my $type;
		if (/_id$/){
			# TODO
			# look into DBH
			# guess target table based on column name
			# see $table_info->{rows}
			# choose an integer space good enough to accomodate that.
			$type = "INTEGER";
		} elsif (/^q\d+$/){
			$type = "TINYINT";
		} else {
			$c->logger->logdie("Don't know how to handle column name '$_' in survery results table '" . $c->table . "'");
		}

		"$_ $type UNSIGNED";
	} @colnames));

	$self->SUPER::do($c);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::Mysql::CreateTable::Results - 

=head1 SYNOPSIS

	use Action::Mysql::CreateTable::Results;

=head1 DESCRIPTION

=cut
