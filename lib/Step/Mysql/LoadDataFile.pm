#!/usr/bin/perl

package Step::Mysql::LoadDataFile;
use base qw/Step::Closure/;
use Step::Closure qw/step/;

use strict;
use warnings;

use File::Basename;

sub new {
	my $pkg = shift;

	my $file = shift;
	my $table_name = shift;

	my $flatten; # optional flattenning for trees
	if ($file =~ /\.tree$/){
		my $flat = File::Spec->catfile(dirname($file), "generated_organizations_tsv.txt");
		{
			my $tree_file = $file;
			$flatten = step "Action::FlattenTree" => sub {
				my $c = $_[1];
				$c->tree_file($tree_file);
				$c->output($flat);
			};
		}

		$file = $flat;
		$table_name ||= "lkup_org";
	};

	$table_name ||= basename($file, qw/.csv .txt .tree/);


	my $analyze = step("Action::AnalyzeDataFile" => sub {
		$_[1]->file($file);
	}, sub {
		$_[1]->export_all;
	});

	$analyze->provides_cxt(1);
	$analyze->depends($flatten || ());

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
	$create->depends($analyze);

	my $self = step("Action::Mysql::LoadDataFile");
	$self->depends($create, $analyze);

	wantarray ? ($self, $create, $analyze, ($flatten || ())) : $self;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Step::Mysql::LoadDataFile - 

=head1 SYNOPSIS

	use Step::Mysql::LoadDataFile;

=head1 DESCRIPTION

=cut
