#!/usr/bin/perl

package Verby::Action::Stub;
use base qw/Verby::Action/;

use strict;
use warnings;

sub do {
	$_[1]->logger->debug("stub do");
}

sub verify {
	$_[1]->logger->debug("stub verify");
	undef;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::Stub - An action which just logs debug messages instead of dying.

=head1 SYNOPSIS

	use Verby::Step::Closure qw/step/;

	my $s = step "Verby::Action::Stub";

=head1 DESCRIPTION

=cut
