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
		perl_module_namespace => 'Acme::Moose', # do we make a Moose.pm? I didn't really understand this part

		project_url => '/premier', # is this for the apache conf?

		dsn => ["dbi:mysql:premier", "premier", "premier.^789"], # used to make maple syroup.
		svn_root => "svn://69.3.245.230/var/svn/infinity-work", # the base URL for the svn_co stuff below
		data_dir => "EERS_demo/data_files", # used to find the basenames of demographics and tables
	},
	
	# just fed steight to LoadData
	data => {
		demographics => {
			# includes proper name, i don't know where to put it though
			# do they get written to a config file? or to a table?
			'Age'           => 'lkup_age.csv',
			'Ethnicity'     => 'lkup_ethnic_group.csv',
			'FTE Status'    => 'lkup_fte_status.csv',
			'Gender'        => 'lkup_gender.csv',
			'Job Family'    => 'lkup_job_family.csv',
			'Manager Level' => 'lkup_manager_level.csv',
			'Organization'  => 'ogranization.tree', # the tree is implicitly flattenned by the load data step, it knows to depend on analyze file etc
		},
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

	# this layout has it's data distilled into a step dep tree:
	# steps with nested children will be a dependedency of their children
	# this is mostly useful for explicit steps, mostly doing mkpath ("dir" steps)
	# the hash minus the 'type' key is passed to the constructor for the appropriate step
	# which can then save that info in it's instance, or closure, and populate the context for the action in due time.
	layout => [ # 'layout' is like sayingt { type => "dir", name => "project root", substeps => ... }
		# a file system aware simplified step dependency tree
		{ type => "dir", name => "htdocs", substeps => { # steps can nest, meaning that substeps depend on their parent
			{ type => "copy", name => "static", source => "..." }, # i don't know what parameter you ment here
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
			{ type => "template", template => "startup.pl" },
			{ type => "template", template => "startup.xml" },
		}},

		{ type => "dir", name => "perl", substeps => {
		 	{ type => "template", template => "..." }, # this has to be the conversion of perl_module_namespace into a file path.
		}},

		# I don't know where these will go based on sample.xml. Perhaps in the 'perl' dir?
		{ type => "svn_co", name => "EERS", repo => "EERS/trunk" }
		{ type => "svn_co", name => "perl", repo => "ii-framework/trunk/lib" }
		{ type => "svn_co", name => "Premier", repo => "premier/trunk" }
	]
};
