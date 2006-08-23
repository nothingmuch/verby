#!/usr/bin/perl

package Verby::Action::Mysql::Util;
use Moose;

has dbh => (
	isa => "Object",
	is  => "ro",
	required => 1,
);

has use_time_piece => (
	isa => "Bool",
	is  => "ro",
	default => 0,
);

has _table_info => (
	isa => "HashRef",
	is  => "ro",
	default => sub { return {} },
);

sub _time_piecify {
	my ( $self, @info ) = @_;
	
	return (wantarray ? @info : $info[0]) unless $self->use_time_piece;

	require Time::Piece;
	require Time::Piece::MySQL;

	my @ret; # return *copies*
	
	foreach my $hash (@info){
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
	my ( $self, @tables ) = @_;

	my @need_query = grep { not exists $self->_table_info->{$_} } @tables;

	@need_query = () if @need_query > 1; # if it's more than one table, get them all
	
	$self->_load_table_status(@need_query);

	$self->_time_piecify(@{ $self->_table_info }{@tables});
}

sub _load_table_status {
    my $self = shift;
	my $pattern = shift;

	my $dbh = $self->dbh;

    my $status = $dbh->prepare('SHOW TABLE STATUS' . ($pattern ? " LIKE " . $dbh->quote($pattern) : ""));
    $status->execute();

    while (my $table_row = $status->fetchrow_hashref('NAME_lc') ) {
        my $name = $table_row->{name};

		$self->_table_info->{$name} = $table_row;

		# can't have placeholders for table names... *sigh*
		my $desc = $dbh->prepare("DESCRIBE $name");
		$desc->execute;
		while (my $col = $desc->fetchrow_hashref){
			push @{ $self->_table_info->{$name}{columns} }, $col;
			$self->_table_info->{$name}{columns_hash}{$col->{Field}} = $col;
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

Copyright 2005, 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
