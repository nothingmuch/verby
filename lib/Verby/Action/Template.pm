#!/usr/bin/perl

package Verby::Action::Template;
use base qw/Verby::Action/;

use strict;
use warnings;

use Template;
use Template::Constants qw( :debug );

sub do {
	my $self = shift;
	my $c = shift;

	my $output = $c->output;
	my $template = $c->template;

	$c->logger->info("templating '$template' into $output");

	my $t = Template->new(ABSOLUTE => 1, DEBUG => DEBUG_UNDEF);

	$t->process($template, $self->template_data($c), $output)
		|| $c->logger->logdie("couldn't process template: " . $t->error);
}

sub template_data {
	my $self = shift;
	my $c = shift;

	+{ c => $c };
}

sub verify {
	my $self = shift;
	my $c = shift;

	my $output = $c->output;
	
	(defined($output) and not ref($output))
		? -e $output
		: undef;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Template - 

=head1 SYNOPSIS

	use Verby::Action::Template;

=head1 DESCRIPTION

=cut
