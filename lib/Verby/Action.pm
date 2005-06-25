#!/usr/bin/perl

package Verby::Action;

use strict;
use warnings;

use Carp qw/longmess/;

sub new {
	my $pkg = shift;
	bless {}, $pkg;
}

sub do {
	die "do(@_) not implemented" . longmess;
}

sub verify {
	die "verify(@_) not implemented" . longmess;
}

sub confirm {
	my $self = shift;
	my $cxt = shift;
	$self->verify($cxt, @_) or
		$cxt->logger->logdie(
			"verification of $self failed: "
			. ($cxt->error || "error unknown"));
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action - 

=head1 SYNOPSIS

	use Verby::Action;

=head1 DESCRIPTION

=cut