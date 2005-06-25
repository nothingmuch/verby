#!/usr/bin/perl

use strict;
use warnings;

die "usage: $0 path/to/datafiles/*.{csv,txt}" unless @ARGV;

use Dispatcher;
use Step::Closure qw/step/;
use Config::Data;
use File::Basename;
use File::Spec;
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

my @load_steps;
my @create_results;
my @create_others;

foreach my $file (@ARGV){
	$logger->debug("making steps for '$file'");
	my $cxt_name = "cxt_" . (0+\$file);

	my ($table_name, $path, $suffix) = fileparse($file, qr/\.(?:csv|txt|tree)/);

	my $flatten;
	if ($file =~ /\.tree$/){
		my $flat = File::Spec->catfile(dirname($file), "generated_lkup_org.txt");
		{
			my $tree_file = $file;
			$flatten = step "Action::FlattenTree" => sub {
				my $c = $_[1];
				$c->tree_file($tree_file);
				$c->output($flat);
			};
		}

		$file = $flat;
		$table_name = "lkup_org";
	}
	
	my $analyze = step("Action::AnalyzeDataFile" => sub {
		$_[1]->file($file);
	}, sub {
		$_[1]->export_all;
	});

	$analyze->provides_cxt(1);
	$analyze->depends($flatten || ());;

	my $type;
	for ($table_name){
		$type = "Hewitt" if /hewitt_norms/;
		$type = "Results" if /survey_results/;
		$type ||= "Demographics";
	}
	my $create = step "Action::Mysql::CreateTable::$type" => sub {
		$_[1]->table($table_name);
		$_[1]->export("table");
	};
	$create->provides_cxt(1);
	
	my $load = step "Action::Mysql::LoadDataFile";

	if ($table_name =~ /survey_results/){
		push @create_results, $create;
	} else {
		push @create_others, $create;
	}

	$load->depends($create, $analyze);
	$create->depends($analyze);
	
	push @load_steps, $load;
}

$_->depends($_->depends, @create_others) for @create_results;

$d->add_step($_) for @load_steps;

$d->do_all;

