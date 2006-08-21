#!/usr/bin/perl

use strict;
use warnings;

die "usage: $0 path/to/datafiles/*.{csv,txt}" unless @ARGV;

use Verby::Step::Mysql::LoadDataFile;
use Verby::Dispatcher;
use Verby::Config::Data;
use File::Basename;
use File::Spec;
use DBI;

my $l4pconf = <<L4P;
	log4perl.rootLogger 			= INFO, term

	log4perl.appender.term			= Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.term.layout	= Log::Log4perl::Layout::SimpleLayout::Multiline
L4P
Log::Log4perl::init(\$l4pconf);

my $cfg = Verby::Config::Data->new;
$cfg->data->{dbh} = DBI->connect("dbi:mysql:test");

my $d = Verby::Dispatcher->new;
$d->config_hub($cfg);

my $logger = Log::Log4perl::get_logger;

my @load_steps;
my @create_results;
my @create_others;

foreach my $file (@ARGV){
	next if $file =~ /generated/;
	$logger->debug("making steps for '$file'");

	my ($load, $create) = Verby::Step::Mysql::LoadDataFile->new($file);

	if ($file =~ /survey_results/){
		push @create_results, $create;
	} else {
		push @create_others, $create;
	}

	push @load_steps, $load;
}

$_->depends($_->depends, @create_others) for @create_results;

$d->add_step($_) for @load_steps;

$d->do_all;

