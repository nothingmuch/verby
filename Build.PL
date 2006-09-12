#!/usr/bin/perl -w

use strict;

use Module::Build;

Module::Build->new(
	module_name => 'Verby',
	license => 'perl',
	requires => {
		'perl'                => '5.008',
		'Set::Object'         => '1.17',
		'Log::Log4perl'       => 0,
		'List::MoreUtils'     => 0,
		'Devel::Caller::Perl' => 0,
		'Class::Inspector'    => 0,
		'POE'                 => '0.37',
	},
	auto_features => {
		'Verby::Config::Source::ARGV' => {
			description => "Verby::Config::Source::ARGV - A config data object which gets keys from the command line",
			requires => { 'Getopt::Casual' => 0 },
		},
		'Verby::Action::MkPath' => {
			description => "Verby::Action::MkPath - Path creation action",
			requires => { 'File::Path' => 0 },
		},
		'Verby::Action::RunCmd' => {
			description => "Verby::Action::RunCmd - action baseclass for executing external commands",
			requires => { 'IPC::Run' => 0 },
		},
		'Verby::Action::MySql' => {
			description => "MySQL related actions",
			requires => {
				'DBD::mysql' => 0,
				'Time::Piece' => 0,
			},
		},
		'Verby::Action::Untar' => {
			description => "Verby::Action::Untar - Tarball extraction",
			requires => {
				'Archive::Tar'  => 0,
				'Sub::Override' => 0,
			},
		},
		'Verby::Action::Copy' => {
			description => "Verby::Action::Copy - Rsync copy action",
			requires => { 'File::Rsync' => 0 },
		},
		'Verby::Action::Template' => {
			description => "Verby::Action::Template - Generic Template Toolkit action",
			requires => { 'Template' => 0 },
		}
	},
	build_requires => {
		'Test::More'       => 0,
		'Test::MockObject' => 0,
		'Test::Deep'       => 0,
		'Test::Exception'  => 0,
		'Test::use::ok'    => 0,
		'File::Temp'       => 0,
		'Hash::AsObject'   => 0,
		'Test::Plan'       => 0,
	},
	create_makefile_pl => 'traditional',
	sign => 1,
	dist_author => [
		'Stevan Little <stevan@iinteractive.com>',
		'Yuval Kogman <nothingmuch@woobling.org>',
	],
)->create_build_script;

