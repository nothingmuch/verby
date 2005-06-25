#!t/usr/bin/perl

package Verby::Action::Mysql::LoadDataFile;
use base qw/Verby::Action::Mysql::DoSql/;

use strict;
use warnings;

our $VERSION = '0.01';

use Mysql::Table::MetaData;
use Time::Piece;
use File::stat;

use DBI;

sub do_sql {
	my $self = shift;
	my $c = shift;

	my $dbh = $c->dbh;
	my $table_name = $c->table;
	my $file = $c->file;

	my $fs = $c->field_sep;
	my $ls = $c->line_sep;
	my $skip = $c->skip_lines || 0;

	$c->logger->info("Deleting all records from table '$table_name'");
	{
		local $dbh->{RaiseError} = 0;
		local $dbh->{HandleError} = undef;
		$dbh->do("delete from $table_name");
	}
	
	ATTEMPT: {
		my $accum = ''; # error accumilator
		my $i;
		for my $local ("", "LOCAL"){
			$i++ and $c->logger->debug("retrying with local=$local");
			if (eval {
				local $dbh->{RaiseError} = 1;
				local $dbh->{HandleError} = sub {
					my $err = shift;
					$accum = join("\nError:", $accum, $err); 
					$c->logger->debug($err);
					die $err;
				};
				my $sth = $dbh->prepare(qq{
					LOAD DATA
						$local INFILE ?
						INTO TABLE $table_name
						FIELDS TERMINATED BY ?
						LINES TERMINATED BY ?
						IGNORE ? LINES
				});
				my $i;
				$sth->bind_param(++$i, $_) for ($file, $fs, $ls);
				$sth->bind_param(++$i, $skip, DBI::SQL_INTEGER);
				$sth->execute;
			}){
				$c->logger->info("Successfully loaded '$file', local=" . ($local ? 1 : 0));
				last ATTEMPT;
			} else {
				$c->logger->debug("Couldn't execute SQL: $@");
			}
		}

		$c->logger->logdie("Couldn't load '$file' into table '$table_name': $accum");
	}
}



sub verify {
	my $self = shift;
	my $c = shift;
	
	my $dbh = $c->dbh;
	my $table_name = $c->table;
	my $file = $c->file;

	return undef unless defined $c->stat;
	
	my $file_stamp = localtime($c->stat->mtime);

	my $table_info = Mysql::Table::MetaData->new(
		dbh => $dbh,
		use_time_piece => 1,
	)->get_info($table_name);

	return unless $table_info;
	return unless $file_stamp <= $table_info->{update_time};

	$c->logger->logdie("schema of table '$table_name' doesn't match data file '$file':"
		. " table has " . (scalar @{ $table_info->{columns} }) . " columns"
		. " while file has " . $c->columns . " columns"
	) unless @{ $table_info->{columns} } == $c->columns;

	$table_info->{rows} > 0;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Mysql::LoadDataFile - 

=head1 SYNOPSIS

	use Verby::Action::Mysql::LoadDataFile;

=head1 DESCRIPTION

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>
stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

