#!/usr/bin/perl

package Mysql::Table::MetaData;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my @params = @_;
	unshift @params, "dbh" if @params == 1;

	bless {@params}, $pkg;
}

sub use_time_piece {
	my $self = shift;
	$self->{use_time_piece} = shift if @_;
	$self->{use_time_piece};
}

sub _time_piecify {
	my $self = shift;
	
	return (wantarray ? @_ : $_[0]) unless $self->use_time_piece;

	require Time::Piece;
	require Time::Piece::MySQL;

	my @ret; # return *copies*
	
	foreach my $hash (@_){
		push @ret, undef and next unless $hash;
		my %new = %$hash;
		foreach my $time_key (grep { /_time$/ } keys %new){
			my $piece = Time::Piece->from_mysql_datetime($new{$time_key});
			$piece->[Time::Piece::c_islocal()] = 1; # mysql is SYSTEM time, in general
			$new{$time_key} = $piece;
		}
		push @ret, \%new;
	}

	# scalar context should dwim, rather than be accurate, IMHO
	wantarray ? @ret : $ret[0];
}

sub get_info {
	my $self = shift;
	my @tables = shift;

	my @need_query = grep { not exists $self->{tables}{$_} } @tables;

	@need_query = () if @need_query > 1; # if it's more than one table, get them all
	
	$self->_load_table_status(@need_query);

	$self->_time_piecify(@{ $self->{tables} }{@tables});
}

sub dbh {
	my $self = shift;
	$self->{dbh};
}

sub _load_table_status {
    my $self = shift;
	my $pattern = shift;

	my $dbh = $self->dbh;

    my $status = $dbh->prepare('SHOW TABLE STATUS' . ($pattern ? " LIKE ?" : ""));
    $status->execute($pattern || ());

    while (my $table_row = $status->fetchrow_hashref('NAME_lc') ) {
        my $name = $table_row->{name};

		$self->{tables}{$name} = $table_row;

		# can't have placeholders for table names... *sigh*
		my $desc = $dbh->prepare("DESCRIBE $name");
		$desc->execute;
		while (my $col = $desc->fetchrow_hashref){
			push @{ $self->{tables}{$name}{columns} }, $col;
			$self->{tables}{$name}{columns_hash}{$col->{Field}} = $col;
		}
		$desc->finish;
    }

    $status->finish;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Mysql::Table::MetaData - 

=head1 SYNOPSIS

	use Mysql::Table::MetaData;

=head1 DESCRIPTION

=cut
