#!/usr/bin/perl

package Verby::Action::Make;
use base qw/Verby::Action::RunCmd/;

use strict;
use warnings;

sub start {
	my $self = shift;
	my $c = shift;

	my $wd = $c->workdir;
	my @targets = (($c->target || ()), @{ $c->targets || [] });

	$c->is_make_test(1) if "@targets" eq "test";

	$self->cmd_start($c, [qw/make -C/, $wd, @targets]);
}

sub finish {
	my $self = shift;
	my $c = shift;

	$c->done(1);
	$self->SUPER::finish($c);
	
	my $out = ${ $c->stdout_ref };
	chomp($out) and $c->logger->info("test output:\n$out") if $c->is_make_test;
}

sub log_extra {
	my $self = shift;
	my $c = shift;

	" in " . $c->workdir;
}

sub verify { $_[1]->done }

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Make - 

=head1 SYNOPSIS

	use Verby::Action::Make;

=head1 DESCRIPTION

=cut
