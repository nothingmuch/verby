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

	# always logdie
	local $dbh->{PrintError} = 0;
	local $dbh->{RaiseError} = 0;
	local $dbh->{HandleSetErr} = sub { $c->logger->logdie(shift) };

	$c->logger->info("Deleting all records from table '$table_name'");
	$dbh->do("delete from $table_name");
	
	ATTEMPT: {
		for my $local ("", "LOCAL"){
			if (eval {
				local $dbh->{HandleError} = sub { $c->logger->debug($_[0]); die $_[0] };
				$dbh->prepare(qq{
					LOAD DATA
						$local INFILE ?
						INTO TABLE $table_name
						FIELDS TERMINATED BY ?
						LINES TERMINATED BY ?
				})->execute($file, $fs, $ls);
			}){
				$c->logger->info("Successfully loaded '$file', local=" . ($local ? 1 : 0));
				last ATTEMPT;
			};
		}

		$c->logger->logdie("Couldn't load '$file' into table '$table_name'");
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

	return 1;
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

