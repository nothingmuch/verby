#!/usr/bin/perl

package Action::Stub;
use base qw/Action/;

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

Action::Stub - 

=head1 SYNOPSIS

	use Action::Stub;

=head1 DESCRIPTION

=cut
