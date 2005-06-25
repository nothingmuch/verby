#!/usr/bin/perl

package Config::Interpreter;

use strict;
use warnings;

use File::Spec;
use Config::Data;

use Verby::Step::Closure qw/step/;
use Verby::Step::Mysql::LoadDataFile;

sub new {
	my $pkg = shift;

	bless {
		config => shift,

		# used to keep track of state
		steps => [], # collects all the steps
		stack => [], # the stack of parents of the current substep
		substeps_by_parent_id => {}, # all the sub-steps of a given step id
		substeps_stack => [], # used to fill in substeps_by_parent_id
		depenadnt_by_dep_id => {}, # used to track via the id of a step, which steps depend on it (or actually all it's children)

		# special cases
		dir_stack => [], # used to construct full paths from nested 'dir' steps
		create_results => [], # all the create table actions for result tables. Constructed after demographics:
		create_demographics => [], # all the create table actions for demographics tables.
	}, $pkg;
}

sub prepare_dispatcher {
	my $self = shift;
	my $d = shift;

	require Log::Log4perl and Log::Log4perl::init(\$self->{config}{conf}{log4perl_conf})
		if exists $self->{config}{conf}{log4perl_conf};

	$self->traverse($self->{config}{steps});

	my $cfg = Config::Data->new;
	%{ $cfg->data } = %{ $self->{config}{conf} };

	$d->config_hub($cfg);

	$d->add_steps(@{ $self->{steps} });

	$d;
}

sub unwrap_extra_deps {
	my $self = shift;
	foreach my $name (keys %{ $self->{depenadnt_by_dep_id} }){
		foreach my $step (@{ $self->{depenadnt_by_dep_id}{$name} }){
			$step->add_deps($self->{substeps_by_parent_id}{$name});
		}
	}
	$_->add_deps(@{ $self->{create_demographics} }) for @{ $self->{create_results} };
}

sub traverse {
	my $self = shift;
	my $s = shift || return;

	foreach my $struct (map { $self->explode_file_globs($_) } @$s){
		my $step_obj = $self->mk_step($struct);
		$self->push_step($step_obj, $struct) if $step_obj;
		$self->traverse($struct->{substeps});
		$self->pop_step($step_obj, $struct) if $step_obj;
	}
}


sub push_step {
	my $self = shift;
	my $step = shift;
	my $struct = shift;

	push @{ $self->{stack} }, $step;

	push @{ $self->{group_stack} }, ($self->{substeps_by_parent_id}{$struct->{id}} = [ $step ])
		if exists $struct->{id}; # FIXME this should be prettier, like with a meta step, or only the leaves

	push @{$_}, $step for @{ $self->{group_stack} };

	push @{ $self->{dir_stack} }, $struct->{path} if $struct->{type} eq "dir";
}

sub pop_step {
	my $self = shift;
	my $step = shift;
	my $s = shift;
	pop @{ $self->{group_stack} } if exists $s->{id};
	pop @{ $self->{dir_stack} } if $s->{type} eq "dir";
	pop @{ $self->{stack} };
}

sub explode_file_globs {
	my $self = shift;
	my $s = shift;
	return $s unless ref $s eq "HASH" and exists $s->{file_glob};
	map { { %$s, file => $_ } } glob(File::Spec->catfile($self->{config}{conf}{data_dir}, $s->{file_glob}));
}

sub mk_step {
	my $self = shift;
	my $step_struct = shift;

	$step_struct->{type} ||= "noop";

	my $method = "mk_step_$step_struct->{type}";

	$self->can($method)
		or die "unknown step type $step_struct->{type}";
	
	my $obj = $self->$method($step_struct)
		or die "couldn't make step " . Dumper($step_struct);

	$obj->add_deps($self->{stack}[-1]) if @{ $self->{stack} };

	push @{ $self->{depenadnt_by_dep_id}{$step_struct->{depends}} }, $obj if $step_struct->{depends};
	push @{ $self->{steps} }, $obj;
	
	$obj;
}

sub mk_step_dir {
	my $self = shift;
	my $s = shift;

	# derive the full path from the @dir_stack
	my $path = $self->absolute_path($s->{path});
	
	step "Verby::Action::MkPath", sub {
		$_[1]->path($path);	
	};
}

sub mk_step_load {
	my $self = shift;
	my $s = shift;

	my $basename = $s->{file};
	my $file = (File::Spec->file_name_is_absolute($basename) || -e $basename)
		? $basename
		: File::Spec->catfile($self->{config}{conf}{data_dir}, $basename);

	my $proper_name = $s->{proper_name} || "";
	(my $id = lc($proper_name)) =~ s/\s+/_/g;

	my ($load, $create) = Verby::Step::Mysql::LoadDataFile->new($file, ($s->{table_name} || ()));

	if ($basename =~ /survey_results/){
		push @{$self->{create_results}}, $create;
	} else {
		push @{$self->{create_demographics}}, $create;
	}

	$create->post(sub {
		my $c = $_[1];

		# fill in the global config for the templates, if the table has a proper name
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
}

sub mk_step_template {
	my $self = shift;
	my $s = shift;
	my $basename = $s->{template};
	my $template = File::Spec->catfile($self->{config}{conf}{template_dir}, $basename);
	my $output = $s->{output} ||= $self->absolute_path($basename);
	step "Verby::Action::Template", sub {
		$_[1]->template($template);
		$_[1]->output($output);
	};
}

sub mk_step_perl_module {
	my $self = shift;
	my $s = shift;

	# munge params for the template step
	my @path = split /::/, $s->{package};
	my $basename = (pop @path) . ".pm";
	$s->{output} = $self->absolute_path(File::Spec->catfile(@path, $basename));

	$self->mk_step_template($s);
}

sub mk_step_copy {
	my $self = shift;
	my $s = shift;
	
	my $dest = $self->absolute_path($s->{path});
	my $source = $s->{source};

	my $append = ((-d $source) ? "/" : "");
	
	step "Verby::Action::Copy", sub {
		$_[1]->source($source . $append || '');
		$_[1]->dest($dest . $append || '');
	};
}

sub mk_step_svn_co { $_[0]->mk_step_stub }
sub mk_step_test_run { $_[0]->mk_step_stub }
sub mk_step_noop { $_[0]->mk_step_stub }
sub mk_step_stub { step "Verby::Action::Stub" }

sub absolute_path { # with respect to @dir_stack
	my $self = shift;
	my $name = shift;

	return $name if File::Spec->file_name_is_absolute($name) or -e $name;
	my @path;
	foreach my $level ($name, reverse @{ $self->{dir_stack} }){
		push @path, $level;
		last if File::Spec->file_name_is_absolute($level); # don't go past absolute parents
	}
	File::Spec->catdir(reverse @path);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Config::Interpreter - Takes the deep structure produced by
L<Config::Source::XML>, and uses the data therein to prepare a
L<Verby::Dispatcher>.

=head1 SYNOPSIS

	# create the objects involved
	my $d = Verby::Dispatcher->new;
	my $c = Config::Source::XML->new;

	# load the steps into the dispatcher
	my $i = Config::Interpreter->new($c->load("config.xml"));
	$i->prepare_dispatcher($d);

	# do the work
	$d->do_all;

=head1 DESCRIPTION

This is the code that "understands" the configuration tree produced by
L<Config::Source::XML>.

The hash ref returned by the XML parser has two keys, C<config> and C<steps>.
C<config> is copied into the context hub, it's pretty boring.

The C<steps> structure is more interesting.

It's an array reference containing hash references. Each hash ref represents a
single step. It has a C<type> key set, which is used to call the appropriate
method to create a new step.

There's also an optional C<id> tag, to identify a step, and a C<depends> tag,
to facilitate arbitrary dependencies.

If the hash contains a C<substeps> value, which is an array ref, then this is
recursively traversed like the top level C<steps>.

Each sub step depends on it's parent automatically.

All other fields are arbitrary, and are used by the appropriate C<mk_step>
method, and eventually end up in C<Verby::Step::Closure> callbacks, controlling
the behavior of the action.

=head1 STEP TYPES

=head2 C<dir>

Creates a C<Verby::Action::MkPath> closure step. If the path given is relative,
then the parent C<dir>s are concatenated with C<File::Spec>, until the path is
relative or we run out of parents.

This means that nested substeps will not only depend on each other, but also
nest in the file system.

=head2 C<load>

This loads a data file. This operation really creates three or four steps -
tree flattenning if applicable, data file analysis, table creation, and actual
loading.

This complexity is hidden by C<Verby::Step::Mysql::LoadDataFile>.

C<table_name> can override the guessed table name, and C<proper_name> is used
by one of the templating step.

The C<file> argument finds a basename in the C<data_dir> config var. More
interetingly the C<file_glob> step will explode the traversal, much like
junctive autothreading, creating a step for each file matching the glob. An
example of how this is used is C<tbl_survey_results_*.csv>

=head2 C<svn_co>

Check out the SVN URL in C<repo> (based on C<svn_root> in the config), into
C<path>.

Not yet implemented.

=head2 C<copy>

Copies C<source> to C<path> using L<Verby::Action::Copy>.

=head2 C<template>

Uses L<Verby::Action::Template>, taking the C<template> basename from
C<template_dir>, and outputting the same template file in the "current
directory" as implied by the C<dir> stacking behavior.

=head2 C<perl_module>

A thin wrapper for C<template> which takes a perl namespace, such as
C<Acme::Moose>, and outputs the file C<Acme/Moose.pm>.

=head2 C<test_run>

Runs the test suite by running C<prove -Ilib t/>.

Not yet implemented.

=head1 METHODS

=head2 Public

=over 4

=item new $config

Create a new interpreter. The parameter should be the one returned by L<Config::Source::XML/load>.

=item prepare_dispatcher $dispatcher

Traverses the config given to C<new>, unwraps extra dependencies, makes a
C<Config::Data> out of the $config's C<config> key, sets $dispatcher's
C<config_hub> to that, and then adds all the steps to $dispatcher.

=back

=head2 Internal

=over 4

=item mk_step $struct

Used internally to dispatch step creation, doing the book keeping.

=item mk_step_copy

=item mk_step_dir

=item mk_step_load

=item mk_step_noop

=item mk_step_perl_module

=item mk_step_stub

=item mk_step_svn_co

=item mk_step_template

=item mk_step_test_run

These facilitate the creation of a step of C<type> foo.

=item traverse $array_ref

Traverses a step structure, maintaining the stacks, and calling C<mk_step>.
Also calls C<explode_file_globs> when that key is met.

=item push_step $step

=item pop_step $step

Maintains the various stacks needed for the nesting semantics.

=item unwrap_extra_deps

Used after a traversal to add the C<depends>/C<id> relationships, when the full
data set is known.

=item absolute_path

Returns an absolute path (or at least tries to) based on the parent C<dir>
steps of the current substep. This is used to logically position subdirectories
and output file basenames in the output tree.

=item explode_file_globs

Creates N steps with a C<file> key from one step with a C<file_glob> key, by
expanding the glob inside C<data_dir>.

=back

=cut
