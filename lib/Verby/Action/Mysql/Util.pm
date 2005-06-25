#!/usr/bin/perl

package Verby::Action::Mysql::Util;

use strict;
use warnings;

our $VERSION = '0.01';

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

Verby::Action::Mysql::Util - A table introspection utility library.

=head1 SYNOPSIS

	use Verby::Action::Mysql::Util;

	my $m = Verby::Action::Mysql::Util->new(
		dbh => $dbh,
		use_time_piece => 1, # date objects are Time::Piece
	);

	my $table_info = $m->get_info("table_name");

	my $time_piece = $table_info->{update_time};

=head1 DESCRIPTION

This utility module knows to query a MySQL database handle for into regarding a
table, mostly concerning the structure metadata itself.

=head1 METHODS

=over 4

=item new DBH

=item new PARAMS

Create a new meta data extractor thingamabob.

It takes either a single database handle, or a list of key/value pairs, with
the key being the name of the corresponding method as named below.

=item get_info TABLE_NAME

This method returns a hash containing the various fields of data regarding a
table.

=item dbh

Returns the database handle being used.

=item use_time_piece BOOL

Returns or set 

=back

=head1 TABLE INFO DATA FIELDS

=over 4

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
