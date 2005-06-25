#!/usr/bin/perl

package EERS::Step::VarWWW;
use base qw/EERS::Step Class::StrongSingleton/;

use strict;
use warnings;

use File::Path qw/mkpath/;
use File::Spec;

sub new {
	my $pkg = shift;
	my $self = bless {}, $pkg;
	$self->_init_StrongSingleton;
	$self;
}

sub satisfied {
	my $self = shift;
	my $dir = $self->_dir;
	-d $dir and -r $dir and -w $dir and -x $dir;
}

sub execute {
	my $self = shift;
	mkpath($self->_dir);
	die "created /var/www is not OK" unless $self->satisfied;
}

sub _dir {
	return File::Spec->catfile(
		File::Spec->rootdir,
		qw/var www/,
	);
}

__PACKAGE__

__END__

=pod

=head1 NAME

EERS::Step::VarTree - Installation step that creates /var/www

=head1 SYNOPSIS

	use EERS::Step::VarTree;

=head1 DESCRIPTION

This step is very simple, and simply creates /var/www if it's not there.

This step's purpose is actually more for error checking. It will die properly,
and early, if we can't create or use /var/www.

=cut
