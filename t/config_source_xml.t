#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Data::Dumper;

use_ok('Verby::Config::Source::XML');


my $conf = Verby::Config::Source::XML->new();
isa_ok($conf, 'Verby::Config::Source::XML');

$conf->load('docs/installer_config.xml');

my $config = $conf->config();

print Dumper $config;