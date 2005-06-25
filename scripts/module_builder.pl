#!/usr/bin/perl

use strict;
use warnings;

use Log::Log4perl qw/:easy/;

use Cwd;

use Verby::Step::Closure qw/step/;
use Verby::Dispatcher;

my $l4pconf = <<L4P;
	log4perl.rootLogger 			= INFO, term

	log4perl.appender.term			= Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.term.layout	= Log::Log4perl::Layout::SimpleLayout::Multiline

	#log4perl.logger.Verby.Dispatcher	= DEBUG
L4P

Log::Log4perl::init(\$l4pconf);

my $cfg = Config::Data->new;
%{ $cfg->data } = (
	untar_dir => cwd,
);

my $d = Verby::Dispatcher->new;
$d->config_hub($cfg);

foreach my $tarball (@ARGV){
	my $mkdir = step "Verby::Action::MkPath" => sub {
		my $self = shift;
		my $c = shift;
		$c->path($c->untar_dir);
	};
	$mkdir->provides_cxt(1);

	my $untar = step "Verby::Action::Untar" => sub {
		my $self = shift;
		my $c = shift;
		$c->tarball($tarball);
		$c->dest($c->untar_dir);
	}, sub {
		my $self = shift;
		my $c = shift;
		$c->export("src_dir") if $c->exists("src_dir");
	};
	$untar->depends($mkdir);

	my $plscript = step "Verby::Action::MakefilePL" => sub {
		my $self = shift;
		my $c = shift;
		$c->workdir($c->src_dir);
	};
	$plscript->depends($untar);

	my $make = step "Verby::Action::Make" => sub {
		my $self = shift;
		my $c = shift;
		$c->workdir($c->src_dir);
	};
	$make->depends($plscript);

	my $test = step "Verby::Action::Make" => sub {
		my $self = shift;
		my $c = shift;
		$c->workdir($c->src_dir);
		$c->target("test");
	};
	$test->depends($make);

	$d->add_step($test);
}

$d->do_all;

