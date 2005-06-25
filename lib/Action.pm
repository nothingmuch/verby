#!/usr/bin/perl

package Action;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	bless {}, $pkg;
}

sub do {
	die "not implemented";
}

sub verify {
	die "not implemented";
}

sub confirm {
	my $self = shift;
	my $cxt = shift;
	$self->verify($cxt, @_) or
		die "verification of $self failed: "
		. ($cxt->error || "error unknown");
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action - 

=head1 SYNOPSIS

	use Action;

=head1 DESCRIPTION

=cut
