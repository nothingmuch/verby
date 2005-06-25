#!/usr/bin/perl

package Verby::Action::SvnCheckout;
use base qw/Verby::Action::RunCmd/;

use strict;
use warnings;

use File::Spec;

sub do {
	my $self = shift;
	my $c = shift;

	$self->run($c, ["svn", $c->source, $c->dest]);

	$self->confirm;
}

sub verify {
	my $self = shift;
	my $c = shift;

	my $wd = $c->dest;

	return unless -d $wd
		and -d File::Spec->catdir($wd, ".svn")
		and $self->run($c, [qw/svn up/], undef, sub { chdir $wd });
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::SvnCheckout - 

=head1 SYNOPSIS

	use Verby::Action::SvnCheckout;

=head1 DESCRIPTION

=cut
