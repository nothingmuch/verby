#!/usr/bin/perl

use strict;
use warnings;

use Verby::Config::Source::XML;

use Verby::Dispatcher;
use Verby::Config::Interpreter;

use DBI;

my $conf_file = 'docs/installer_config.xml';

my $conf_parser = Verby::Config::Source::XML->new;
my $config = $conf_parser->load($conf_file);

# this should be handled by the create db step
$config->{conf}{dbh} = DBI->connect(@{ $config->{conf}{database} }{qw/dsn username password/});
#or Log::Log4perl::get_logger("EERS::Installer")->logdie("couldn't connect to dsn: " . DBI->errstr);

Verby::Config::Interpreter->new($config)->prepare_dispatcher(Verby::Dispatcher->new)->do_all;

