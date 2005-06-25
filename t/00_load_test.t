#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

BEGIN {

    use_ok('Verby');

    # Verby
    use_ok('Verby::Action');
    use_ok('Verby::Context');
    use_ok('Verby::Dispatcher');
    use_ok('Verby::Step');

        # Verby/Step
        use_ok('Verby::Step::Closure');
        use_ok('Verby::Step::CreateDB');

        # Verby/Config
        use_ok('Verby::Config::Data');
        use_ok('Verby::Config::Hub');
        use_ok('Verby::Config::Source');

            # Verby/Config/Source
            use_ok('Verby::Config::Source::ARGV');
            use_ok('Verby::Config::Source::Prompt');

            # Verby/Config/Data
            use_ok('Verby::Config::Data::Mutable');

        # Verby/Action
        use_ok('Verby::Action::Copy');
        use_ok('Verby::Action::Make');
        use_ok('Verby::Action::MakefilePL');
        use_ok('Verby::Action::MkPath');
        use_ok('Verby::Action::MysqlCreateDB');
        use_ok('Verby::Action::RunCmd');
        use_ok('Verby::Action::Stub');
        use_ok('Verby::Action::SvnCheckout');
        use_ok('Verby::Action::Template');
        use_ok('Verby::Action::Untar');

            # Verby/Action/Mysql
            use_ok('Verby::Action::Mysql::CreateTable');
            use_ok('Verby::Action::Mysql::DoSql');
            use_ok('Verby::Action::Mysql::LoadDataFile');

    # Log

        # Log/Log4perl

            # Log/Log4perl/Layout

                # Log/Log4perl/Layout/SimpleLayout
                use_ok('Log::Log4perl::Layout::SimpleLayout::Multiline');

};

