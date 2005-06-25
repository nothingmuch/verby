#!/usr/bin/perl

use strict;
use warnings;

die "usage: $0 path/to/datafiles/*.{csv,txt}" unless @ARGV;

use Dispatcher;
use Step::Closure qw/step/;
use Config::Data;
use File::Basename;
use DBI;

my $l4pconf = <<L4P;
	log4perl.rootLogger 			= INFO, term

	log4perl.appender.term			= Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.term.layout	= Log::Log4perl::Layout::SimpleLayout::Multiline
L4P
Log::Log4perl::init(\$l4pconf);

my $cfg = Config::Data->new;
$cfg->data->{dbh} = DBI->connect("dbi:mysql:test");

my $d = Dispatcher->new;
$d->config_hub($cfg);

my $logger = Log::Log4perl::get_logger;

$logger->info("Table prefix is $$");

foreach my $file (grep { !/survey_results/ } @ARGV){
	$logger->info("making steps for '$file'");
	my $cxt_name = "cxt_" . (0+\$file);

	my ($table_name, $path, $suffix) = fileparse($file, qr/\.(?:csv|txt|tree)/);
	$table_name = join("_", $$, $table_name);

	my $steal_cxt = sub {
		my $self = shift;
		my $c = shift;

		# i'm sorry, Stevan....
		(tied %{ $c->data })->[1] = (tied %{ $c->$cxt_name->data })->[1]; #
	};
	
	my $analyze = step("Action::AnalyzeDataFile" => sub {
		my $self = shift;
		my $c = shift;

		$c->file($file);
		$c->table($table_name);
	}, sub {
		# reexport the actual context... see above
		my $self = shift;
		my $c = shift;
		$c->$cxt_name($c);
		$c->export($cxt_name);
	});

	my $load = &step("Action::Mysql::LoadDataFile" => $steal_cxt);
	my $create = &step("Action::Mysql::CreateTable::AdHoc" => $steal_cxt);

	$load->depends($create, $analyze);
	$create->depends($analyze);

	$d->add_step($load);
}

$d->do_all;

exit;

{
	package Action::Mysql::CreateTable::AdHoc;
	use base qw/Action/;

	use Data::Dumper;
	
	sub verify { undef }

	sub do {
		my $self = shift;
		my $c = shift;

		my $dbh = $c->dbh;
		my $table_name = $c->table;

		local $dbh->{PrintError} = 0;
		local $dbh->{RaiseError} = 0;
		local $dbh->{HandleError} = sub {
			my $msg = shift;
			$c->logger->warn($msg) unless $msg =~ /already exists/; # blah blah blah
		};
		
		if ($table_name =~ /hewitt_norms/){
			$c->logger->info("creating hewitt table");
			$dbh->do(qq{
				CREATE TABLE $table_name (
					question_id MEDIUMINT UNSIGNED, 
					scoretype_id TINYINT UNSIGNED,
					score TINYINT UNSIGNED
				);
			});
		} elsif ($c->columns == 2){
			$c->logger->info("creating demographics table '$table_name'");
			$dbh->do(qq{
				CREATE TABLE $table_name (
					id INT PRIMARY KEY,
					description VARCHAR(255)
				)
			});
		} else {
			$c->logger->warn("Don't know how to create table: "
			. Dumper({ map { $_ => $c->$_ } grep { !/^cxt_/ } keys %{ $c->data } }));
		}
	}

}
