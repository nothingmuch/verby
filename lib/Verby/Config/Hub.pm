#!/usr/bin/perl

package Verby::Config::Hub;
use Module::Pluggable (
	sub_name => "sources",
	search_path => ["Verby::Config::Source"],
	instantiate => "new",
);

use strict;
use warnings;

sub new {
	my $pkg = shift;

	tie my %data, 'Tie::HashDefaults', map { $_->data } my @sources = $pkg->sources;
	bless {
		sources => \@sources,
		data => \%data,
	}, $pkg;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Config::Hub - 

=head1 SYNOPSIS

	use Verby::Config::Hub;

=head1 DESCRIPTION

=cut
