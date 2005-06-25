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
		steps => [],
		stack => [],
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

	use Config::Interpreter;

=head1 DESCRIPTION

This is the code that "understands" the configuration tree produced by
L<Config::Source::XML>.

=cut
