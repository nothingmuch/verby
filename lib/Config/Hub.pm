#!/usr/bin/perl

package Config::Hub;
use Module::Pluggable (
	sub_name => "sources",
	search_path => ["Config::Source"],
	instantiate => "new",
);

use strict;
use warnings;

sub new {
	my $pkg = shift;

	tie my %data, 'Tie::HashDefaults', map { $_->data } my @sources = $self->sources;
	bless {
		sources => \@sources,
		data => \%data,
	}, $pkg;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Config::Hub - 

=head1 SYNOPSIS

	use Config::Hub;

=head1 DESCRIPTION

=cut
