#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use constant HAVE_DBD_MYSQL => eval { require DBD::mysql; 1 } || 0;
use constant HAVE_FILE_RSYNC => eval { require File::Rsync; 1 } || 0 ;
use constant HAVE_GETOPT_CASUAL => eval { require Getopt::Casual; 1 } || 0;

use ok "Verby";

use ok "Verby::Dispatcher";

use ok "Verby::Context";
use ok "Verby::Config::Data";
use ok "Verby::Config::Data::Mutable";
use ok "Verby::Config::Source";
use if HAVE_GETOPT_CASUAL, ok => "Verby::Config::Source::ARGV";
use ok "Verby::Config::Source::Prompt";
use ok "Verby::Config::Hub";

use ok "Verby::Action";

use ok "Verby::Action::Stub";

use ok "Verby::Action::MkPath";

use ok "Verby::Action::RunCmd";
use ok "Verby::Action::Untar";
use ok "Verby::Action::Make";
use ok "Verby::Action::MakefilePL";
use if HAVE_FILE_RSYNC, ok => "Verby::Action::Copy";

use if HAVE_DBD_MYSQL, ok => "Verby::Action::Mysql::CreateDB";
use if HAVE_DBD_MYSQL, ok => "Verby::Action::Mysql::CreateTable";
use if HAVE_DBD_MYSQL, ok => "Verby::Action::Mysql::DoSql";
use if HAVE_DBD_MYSQL, ok => "Verby::Action::Mysql::LoadDataFile";

use ok "Verby::Action::Template";

use ok "Verby::Step";

use ok "Verby::Step::Closure";
