#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

BEGIN {

    # Log/Log4perl/Layout/SimpleLayout
    use_ok('Log::Log4perl::Layout::SimpleLayout::Multiline');

    # Config
    use_ok('Config::Data');
    use_ok('Config::Hub');
    use_ok('Config::Source');

        # Config/Source
        use_ok('Config::Source::ARGV');
        use_ok('Config::Source::XML');

        # Config/Data
        use_ok('Config::Data::Mutable');

    # Verby
    use_ok('Verby::Dispatcher');    
    use_ok('Verby::Action');
    use_ok('Verby::Context');
    use_ok('Verby::Step');

        # Verby/Step
        use_ok('Verby::Step::Closure');
        use_ok('Verby::Step::CreateDB');

            # Verby/Step/Mysql
            use_ok('Verby::Step::Mysql::LoadDataFile');

        # Verby/Action
        use_ok('Verby::Action::AnalyzeDataFile');
        use_ok('Verby::Action::Copy');
        use_ok('Verby::Action::FlattenTree');
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

                # Verby/Action/Mysql/CreateTable
                use_ok('Verby::Action::Mysql::CreateTable::Demographics');
                use_ok('Verby::Action::Mysql::CreateTable::Hewitt');
                use_ok('Verby::Action::Mysql::CreateTable::Results');

};

