#!/usr/bin/perl

package Verby::Action::Template;
use base qw/Verby::Action/;

use strict;
use warnings;

our $VERSION = '0.01';

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

Verby::Action::Template - Action to process Template Toolkit files

=head1 SYNOPSIS

	use Verby::Action::Template;

=head1 DESCRIPTION

This Action, given a set of template data, will process Template Toolkit files and return their output.

=head1 METHODS 

=over 4

=item B<do>

=item B<template_data>

=item B<verify>

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
