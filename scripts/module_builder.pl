#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use List::Util qw/shuffle/;

use Step::Closure qw/step/;
use Dispatcher;

{
	package Blurter;
	sub AUTOLOAD {
		our $AUTOLOAD =~ /::([^:]+)$/;
		shift;
		warn "$1: @_\n";
	}
}

my $cfg = Config::Data->new;
%{ $cfg->data } = (
	untar_dir => cwd,
	tarball => shift,
	logger => "Blurter",
);

my $mkdir = step "Action::MkPath" => sub {
	my $self = shift;
	my $c = shift;
	$c->path($c->untar_dir);
};

my $untar = step "Action::Untar" => sub {
	my $self = shift;
	my $c = shift;
	$c->tarball($c->tarball);
	$c->dest($c->untar_dir);
}, sub {
	my $self = shift;
	my $c = shift;
	$c->export("src_dir") if $c->src_dir;
};
$untar->depends($mkdir);

my $plscript = step "Action::MakefilePL" => sub {
	my $self = shift;
	my $c = shift;
	$c->workdir($c->src_dir);
};
$plscript->depends($untar);

my $make = step "Action::Make" => sub {
	my $self = shift;
	my $c = shift;
	$c->workdir($c->src_dir);
};
$make->depends($plscript);

my $test = step "Action::Make" => sub {
	my $self = shift;
	my $c = shift;
	$c->workdir($c->src_dir);
	$c->target("test");
};
$test->depends($make);

my $d = Dispatcher->new;
$d->config_hub($cfg);
$d->add_step($_) for shuffle($mkdir, $untar, $make, $test); # ;-)

$d->do_all;


