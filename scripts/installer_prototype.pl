#!/usr/bin/perl

use strict;
use warnings;

use Config::Data;
use Config::Source::XML;
use File::Spec;

use Verby::Dispatcher;
use Verby::Step::Closure qw/step/;
use Verby::Step::Mysql::LoadDataFile;

use DBI;

my $conf_xml = Config::Source::XML->new;
my %config = %{ $conf_xml->load('docs/installer_config.xml') };

die $@ if $@;

my $l4pconf = <<L4P;
	log4perl.rootLogger 			= INFO, term
	log4perl.logger.EERS.Installer	= INFO
	#log4perl.logger.Verby.Dispatcher		= DEBUG

	log4perl.appender.term			= Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.term.layout	= Log::Log4perl::Layout::SimpleLayout::Multiline
L4P
Log::Log4perl::init(\$l4pconf);

my $l = Log::Log4perl::get_logger("EERS::Installer");

my @steps; # catch all for all the steps created, thrown at the dispatcher later
my @stack; # used to track substeps
my %substeps_of_named; # for example all steps under the group 'demographics' will be recorded here
my @group_stack; # a stack for the groups to append the new steps to
push @group_stack, ($substeps_of_named{root} = []); # create a root level, because that's cute
my %dependant_by_group; # objects which explicitly depend on a group will be put here

# special cases
my @dir_stack; # used to track directory names during traversal
my @create_results;
my @create_demographics;

# this dispatch table converts step types into objects
my %create_table; %create_table = (
	dir => sub {
		my $s = shift;

		# derive the full path from the @dir_stack
		my $path = absolute_path($s->{path});
		
		step "Verby::Action::MkPath", sub {
			$_[1]->path($path);	
		};
	},
	load => sub {
		my $s = shift;

		my $basename = $s->{file};
		my $file = (File::Spec->file_name_is_absolute($basename) || -e $basename)
			? $basename
			: File::Spec->catfile($config{conf}{data_dir}, $basename);

		my $proper_name = $s->{proper_name} || "";
		(my $id = lc($proper_name)) =~ s/\s+/_/g;

		my ($load, $create) = Verby::Step::Mysql::LoadDataFile->new($file, ($s->{table_name} || ()));

		if ($basename =~ /survey_results/){
			push @create_results, $create;
		} else {
			push @create_demographics, $create;
		}

		$create->post(sub {
			my $c = $_[1];

			my $g = ((($c->parents)[0]->parents)[0]->parents)[0];
			push @{ $g->data->{demographics} ||= [] }, {
				id => $id,
				proper_name => $proper_name,
				table => {
					id => scalar($c->id_column),
					name => $c->table,
				},
			} if $id;
		});
		
		$load;
	},
	svn_co => sub { step "Verby::Action::Stub" },
	template => sub {
		my $s = shift;
		my $basename = $s->{template};
		my $template = File::Spec->catfile($config{conf}{template_dir}, $basename);
		my $output = $s->{output} ||= absolute_path($basename);
		step "Verby::Action::Template", sub {
			$_[1]->template($template);
			$_[1]->output($output);
		};
	},
	perl_module => sub {
		my $s = $_[0]; # no shift because of goto
		my @path = split /::/, $s->{package};
		my $basename = (pop @path) . ".pm";
		$s->{output} = absolute_path(File::Spec->catfile(@path, $basename));
		goto $create_table{"template"}; # SUPER:: ;-)
	},
	copy => sub {
		my $s = shift;
		
		my $dest = absolute_path($s->{path});
		my $source = $s->{source};

		my $append = ((-d $source) ? "/" : "");
		
		step "Verby::Action::Copy", sub {
			$_[1]->source($source . $append || '');
			$_[1]->dest($dest . $append || '');
		};
	},
	test_run => sub { step "Verby::Action::Stub" },
	noop => sub { step "Verby::Action::Stub" },
);

$l->info("traversing...");
traverse($config{steps});

$l->info("unwrapping additional dependencies deps...");
foreach my $name (keys %dependant_by_group){
	foreach my $step (@{ $dependant_by_group{$name} }){
		$step->depends($substeps_of_named{$name});
	}
}
$_->depends($_->depends, @create_demographics) for @create_results;

$l->info("registering steps with dispatcher");
my $d = Verby::Dispatcher->new;

my $cfg = Config::Data->new;
%{ $cfg->data } = (
	dbh => scalar DBI->connect(@{ $config{conf}{database} }{qw/dsn username password/}) || die("couldn't connect to dsn: " . DBI->errstr),
	%{ $config{conf} },
);

$d->config_hub($cfg);

$d->add_step($_) for @steps;

$l->info("dispatching");

$d->do_all;

$l->info("exiting");

exit;

sub traverse {
	my $s = shift;

	foreach my $struct (map { explode_file_globs($_) } @$s){
		my $step_obj = mk_step($struct);
		push_step($step_obj, $struct) if $step_obj;
		push @group_stack, $substeps_of_named{$struct->{id}} = [ $step_obj ] if exists $struct->{id}; # FIXME this should be prettier, like with a meta step, or only the leaves
		traverse($struct->{substeps});
		pop @group_stack if exists $struct->{id};
		pop_step($step_obj, $struct) if $step_obj;
	}
}

sub explode_file_globs {
	my $s = shift;
	return $s unless ref $s eq "HASH" and exists $s->{file_glob};
	map { { %$s, file => $_ } } glob(File::Spec->catfile($config{conf}{data_dir}, $s->{file_glob}));
}

sub push_step {
	my $step = shift;
	my $struct = shift;

	push @stack, $step;
	push @{$_}, $step for @group_stack;

	push @dir_stack, $struct->{path} if $struct->{type} eq "dir";
}

sub pop_step {
	pop @stack;
	pop @dir_stack if $_[1]->{type} eq "dir";
}

sub mk_step {
	my $step_struct = shift;

	$step_struct->{type} ||= "noop";

	my $obj = &{ $create_table{$step_struct->{type}} }($step_struct)
		or die "couldn't make step " . Dumper($step_struct);

	$obj->depends($obj->depends, $stack[-1]) if @stack;

	push @{ $dependant_by_group{$step_struct->{depends}} }, $obj if $step_struct->{depends};
	push @steps, $obj;
	
	$obj;
}

sub absolute_path { # with respect to @dir_stack
	my $name = shift;
	return $name if File::Spec->file_name_is_absolute($name) or -e $name;
	my @path;
	foreach my $level ($name, reverse @dir_stack){
		push @path, $level;
		last if File::Spec->file_name_is_absolute($level); # don't go past absolute parents
	}
	File::Spec->catdir(reverse @path);
}

