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

	local $dbh->{RaiseError} = 1;

	$c->logger->info("Deleting table '$table_name'");
	$dbh->do("delete from $table_name");
	
	ATTEMPT: {
		for my $local ("", "LOCAL"){
			if (eval {
				$dbh->prepare(qq{
					LOAD DATA
						$local INFILE ?
						INTO TABLE $table_name
						FIELDS TERMINATED BY ?
						LINES TERMINATED BY ?
				})->execute($file, $self->analyze_file($c));
			}){
				$c->logger->info("Successfully loaded '$file', local=" . ($local ? 1 : 0));
				last ATTEMPT;
			} else {
				$c->logger->warn("Couldn't load '$file', local=" . ($local ? 1 : 0));
			}
		}

		$c->logger->logdie("Couldn't load '$file' into table '$table_name'");
	}

	$self->confirm($c);
}

sub analyze_file {
	my $self = shift;
	my $c = shift;
	
	my $file = $c->file;

	local $\ = \1024; # no need to read too much
	open my $fh, "<", $file;

	my ($field_sep, $line_sep);
	local $_ = <$fh>;
	close $fh;

	/(\015\012|[\r\n])/
		? $line_sep = $1
		: $c->logger->logdie("Can't guess line separator") unless defined $line_sep;

	/([\t,])/
		? $field_sep = $1
		: $c->logger->logdie("Can't guess field separator") unless defined $field_sep;

	return ($field_sep, $line_sep);
}

sub verify {
	my $self = shift;
	my $c = shift;
	
	my $dbh = $c->dbh;
	my $table_name = $c->table;
	my $file = $c->file;

	if (my $meta = Mysql::Table::MetaData->new(
		dbh => $dbh, use_time_piece => 1,
	)->get_info($table_name)){

		my $tbl_stamp = $meta->{update_time};
		my $file_stamp = localtime(stat($file)->mtime);

		return $file_stamp <= $tbl_stamp;
	}

	return undef;
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

