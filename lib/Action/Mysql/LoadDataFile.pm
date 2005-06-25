#!t/usr/bin/perl

package Action::Mysql::LoadDataFile;
use base qw/Action/;

use strict;
use warnings;

use Mysql::Table::MetaData;
use Time::Piece;
use File::stat;

sub do {
	my $self = shift;
	my $c = shift;

	my $dbh = $c->dbh;
	my $table_name = $c->table;
	my $file = $c->file;

	my $fs = $c->field_sep;
	my $ls = $c->line_sep;
	my $skip = $c->skip_lines || 0;

	# always logdie
	local $dbh->{PrintError} = 0;
	local $dbh->{RaiseError} = 0;
	my $accum = '';
	local $dbh->{HandleSetErr} = sub { $accum = join("... and then:\n", $accum, shift); $c->logger->logdie($accum) };

	$c->logger->info("Deleting all records from table '$table_name'");
	$dbh->do("delete from $table_name");
	
	ATTEMPT: {
		for my $local ("", "LOCAL"){
			if (eval {
				local $dbh->{RaiseError} = 1;
				local $dbh->{HandleError} = sub { $c->logger->debug($_[0]); die $_[0] };
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

	$self->confirm($c);
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
	$c->logger->logdie("schema of table '$table_name' doesn't match data file '$file'")
		unless @{ $table_info->{columns} } == $c->columns;

	$table_info->{rows} > 0;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::Mysql::LoadDataFile - 

=head1 SYNOPSIS

	use Action::Mysql::LoadDataFile;

=head1 DESCRIPTION

=cut

