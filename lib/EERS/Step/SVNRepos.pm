#!/usr/bin/perl

package EERS::Step::SVNRepos;
use base qw/EERS::Step Class::StrongSingleton/;

use strict;
use warnings;

use IPC::Run qw//;

sub new {
	my $pkg = shift;
	my $self = bless {
		procs => [], # svn process handles are kept here
	}, $pkg;
	$self->_init_StrongSingleton;
	$self;
}

sub depends { "vartree" }

sub satisfied { undef }; # never, always update when rerunning install

sub start {
	my $self = shift;

	foreach my $dir (qw/perl EERS/){
		push @{$self->{procs}}, IPC::Run::start(...); # FIXME destubme
	}	
}

sub finish {
	my $self = shift;

	while (my $svn = shift @{$self->{procs}){
		IPC::Run::finish($svn) or die "couldn't reap process: $!";
	}
}

__PACKAGE__

__END__

=pod

=head1 NAME

EERS::Step::SVNRepos - check out or update the SVN repos.

=head1 SYNOPSIS

	use EERS::Step::SVNRepos;

=head1 DESCRIPTION

This installation step will check out the C<perl> and C<EERS> repos from SVN,
and place them under /var/www.

=cut
