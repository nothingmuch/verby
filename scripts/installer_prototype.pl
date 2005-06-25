#!/usr/bin/perl

use strict;
use warnings;

use Config::Data;
use File::Spec;

use Dispatcher;
use Step::Closure qw/step/;
use Step::Mysql::LoadDataFile;

use DBI;

my %config = %{ do("docs/installer_config.pl") };
die $@ if $@;

my $l4pconf = <<L4P;
	log4perl.rootLogger 			= INFO, term
	log4perl.logger.EERS.Installer	= INFO
	#log4perl.logger.Dispatcher		= DEBUG

	log4perl.appender.term			= Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.term.layout	= Log::Log4perl::Layout::SimpleLayout::Multiline
L4P
Log::Log4perl::init(\$l4pconf);

my $l = Log::Log4perl::get_logger("EERS::Installer");

my @steps; # catch all for all the steps created, thrown at the dispatcher later
my @stack; # used to track substeps
my %named_steps_groups; # for example all steps under the group 'demographics' will be recorded here
my @group_stack; # a stack for the groups to append the new steps to
push @group_stack, ($named_steps_groups{root} = []); # create a root level, because that's cute
my %dependant_groups; # objects which explicitly depend on a group will be put here

# special cases
my @dir_stack; # used to track directory names during traversal
my @create_results;
my @create_demographics;

# this dispatch table converts step types into objects
my %create_table; %create_table = (
	dir => sub {
		my $s = shift;

		# derive the full path from the @dir_stack

		my $path = name_to_path($s->{name});
		
		step "Action::MkPath", sub {
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

		my ($load, $create) = Step::Mysql::LoadDataFile->new($file, ($s->{table_name} || ()));

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
	svn_co => sub { step "Action::Stub" },
	template => sub {
		my $s = shift;
		my $basename = $s->{template};
		my $template = File::Spec->catfile($config{conf}{template_dir}, $basename);
		my $output = $s->{output} ||= name_to_path($basename);
		step "Action::Template", sub {
			$_[1]->template($template);
			$_[1]->output($output);
		};
	},
	perl_module => sub {
		my $s = $_[0]; # no shift because of goto
		my @path = split /::/, $s->{package};
		my $basename = (pop @path) . ".pm";
		$s->{output} = name_to_path(File::Spec->catfile(@path, $basename));
		goto $create_table{"template"}; # SUPER:: ;-)
	},
	copy => sub {
		my $s = shift;
		my $dest = name_to_path($s->{name});
		my $source = $s->{source};

		my $append = ((-d $source) ? "/" : "");
		
		step "Action::Copy", sub {
			$_[1]->source($source . $append);
			$_[1]->dest($dest . $append);
		};
	},
	test_run => sub { step "Action::Stub" },
);

$l->info("traversing...");
traverse($config{steps});

$l->info("unwrapping additional dependencies deps...");
foreach my $name (keys %dependant_groups){
	foreach my $step (@{ $dependant_groups{$name} }){
		$step->depends(@{ $named_steps_groups{$name} });
	}
}
$_->depends($_->depends, @create_demographics) for @create_results;

$l->info("registering steps with dispatcher");
my $d = Dispatcher->new;

my $cfg = Config::Data->new;
%{ $cfg->data } = (
	%{ $config{conf} },
	dbh => scalar DBI->connect(@{ $config{conf}{dsn} }) || die("couldn't connect to dsn: " . DBI->errstr),
	database => {
		dsn => $config{conf}{dsn}[0],
		username => $config{conf}{dsn}[1] || '',
		password => $config{conf}{dsn}[2] || '',
	}
);

$d->config_hub($cfg);

$d->add_step($_) for @steps;

$l->info("dispatching");

$d->do_all;

$l->info("exiting");

exit;

sub traverse {
	my $structure = shift;
	return unless defined $structure;
	if (ref $structure eq "HASH"){
		traverse_hash($structure);
	} elsif (ref $structure eq "ARRAY") {
		traverse_array($structure);
	} else { die "blah" }
}

sub traverse_hash {
	my $s = shift;

	foreach my $name (keys %$s){
		my $struct = $s->{$name};
		foreach my $struct (explode_file_globs($struct)){
			push @group_stack, ($named_steps_groups{$name} = []); # create a new named group, because that's what $s is
			# add file glob explosion
			my $step_obj = mk_step($struct);
			push_step($step_obj, $struct) if $step_obj;
			traverse((ref $struct eq "HASH") ? $struct->{substeps} : $struct);
			pop_step($step_obj, $struct) if $step_obj;
			pop @group_stack;
		}
	}
}

sub traverse_array {
	my $s = shift;

	foreach my $struct (map { explode_file_globs($_) } @$s){
		my $step_obj = mk_step($struct);
		push_step($step_obj, $struct) if $step_obj;
		traverse($struct->{substeps});
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

	push @dir_stack, $struct->{name} if $struct->{type} eq "dir";
}

sub pop_step {
	pop @stack;
	pop @dir_stack if $_[1]->{type} eq "dir";
}

sub mk_step {
	my $step_struct = shift;
	return unless ref $step_struct eq "HASH" and exists $step_struct->{type};

	foreach my $key (keys %$step_struct){
		if ($key =~ /(.*)_varname/){
			$step_struct->{$1} = $config{conf}{delete $step_struct->{$key}}; # interpolate variables with the global conf
		}
	}
	
	my $obj = &{ $create_table{$step_struct->{type}} }($step_struct)
		or die "couldn't make step " . Dumper($step_struct);

	$obj->depends($stack[-1]) if @stack;

	push @{ $dependant_groups{$step_struct->{depends}} }, $obj if $step_struct->{depends};
	push @steps, $obj;
	
	$obj;
}

sub name_to_path { # with respect to @dir_stack
	my $name = shift;
	return $name if File::Spec->file_name_is_absolute($name) or -e $name;
	my @path;
	foreach my $level ($name, reverse @dir_stack){
		push @path, $level;
		last if File::Spec->file_name_is_absolute($level); # don't go past absolute parents
	}
	File::Spec->catdir(reverse @path);
}

