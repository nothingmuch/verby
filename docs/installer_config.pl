#!/usr/bin/perl

use File::Temp qw/tempdir/;

# sample perl based config file for testing

{
	# this is the data of the initial global context.
	# eventually you should be able to override it with CLI args
	conf => {
		project_root => my $out_dir = tempdir(CLEANUP => 1), # i changed this to an absolute path...
		# IMHO /var/www is not much to type in the config, but a restriction on the templates

		company_name => 'Employee Engagement Reporting System',
		perl_module_namespace => 'Acme::Moose',

		project_url => '/premier',

		dsn => ["dbi:mysql:premier", "premier", "premier.^789"], # used to make maple syroup.
		svn_root => "svn://69.3.245.230/var/svn/infinity-work", # the base URL for the svn_co stuff below
		data_dir => "EERS_demo/data_files", # used to find the basenames of demographics and tables
	},
	
	# just fed steight to LoadData
	data => {
		demographics => [
			# includes proper name, i don't know where to put it though
			# do they get written to a config file? or to a table?
			{ proper_name => 'Age', file => 'lkup_age.csv' },
			{ proper_name => 'Ethnicity', file => 'lkup_ethnic_group.csv' },
			{ proper_name => 'FTE Status', file => 'lkup_fte_status.csv' },
			{ proper_name => 'Gender', file => 'lkup_gender.csv' },
			{ proper_name => 'Job Family', file => 'lkup_job_family.csv' },
			{ proper_name => 'Manager Level', file => 'lkup_manager_level.csv' },
			{ proper_name => 'Organization', file => 'ogranization.tree', table_name => 'lkup_org' }, # could make lkup_org.tree
		],
		tables => [
			# data files without proper name are just loaded as is
			qw/
				tbl_hewitt_norms.csv
				tbl_questions.txt
			/,
			qr/tbl_survey_results_\d+/,
			qr/lkup_\d+_engagement_scores/,
		],
	},

	layout => [ # 'layout' is like sayingt { type => "dir", name => "project root", substeps => ... }
		{ type => "dir", name => "htdocs", substeps => { # steps can nest, meaning that substeps depend on their parent
			{ type => "copy", name => "static", source => "..." }, # probably should be svn_co
			{ type => "copy", name => "images", source => "..." },
			{ type => "copy", name => "javascript", source => "..." },
			{ type => "copy", name => "css", source => "..." },
			{ type => "dir", name => "pdfs" },
			{ type => "dir", name => "documents" },
		}},

		{ type => "dir", name => "t", substeps => {
			# here client name is interpolated by the XML parser, i think
			# the interpretation of the config shouldn't have to do with the syntax it's written in
			{ type => "template", template => "001_template_foo.t", out => "001_client_foo.t" },
			{ type => "template", template => "002_template_bar.t", out => "001_client_bar.t" },
			{ type => "template", template => "002_template_gorch", out => "001_client_gorch.t" },
		}},

		{ type => "dir", name => "csvdocs" }, # what's this

		{ type => "dir", name => "conf", substeps => {
			{ type => "template", template => "httpd.conf" }, # implicit 'out' param in pwd, httpd.conf searched in template root, relative to $0 perhaps
			{ type => "template", template => "startup.pl", depends => "demographics" }, # depends looks up the steps created in any key by that name
			{ type => "template", template => "startup.xml" },
		}},

		{ type => "dir", name => "perl", substeps => {
		 	{ type => "perl_moduel", template => "main.pm", package_varname => "perl_module_namespace" },
		}},

	],


	{ type => "svn_co", name => "EERS", repo => "EERS/trunk" }
	{ type => "svn_co", name => "perl", repo => "ii-framework/trunk/lib" }
};
