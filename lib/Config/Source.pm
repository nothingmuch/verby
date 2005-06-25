#!/usr/bin/perl

package Config::Source;
use base qw/Config::Data/;

use strict;
use warnings;

use Tie::Memoize;

sub new {
	my $pkg = shift;
	tie my %data, 'Tie::Memoize', sub { $pkg->extract(shift) };

	bless { data => \%data }, $pkg;
}

sub extract {
	die "subclass should extract keys from real config source";
}

__PACKAGE__

__END__

=pod

=head1 NAME

Config::Source - 

=head1 SYNOPSIS

	use Config::Source;

=head1 DESCRIPTION

=cut
