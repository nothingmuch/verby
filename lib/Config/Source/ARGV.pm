#!/usr/bin/perl

package Config::Source::ARGV;
use base qw/Config::Data/;

use strict;
use warnings;

use Getopt::Casual;

sub new {
	my $self = shift->SUPER::new(@_);

	%{ $self->{data} } = map {
		(my $key = $_) =~ s/^-+//; # Getopt::Casual exposes '--foo', etc.
		$key => $ARGV{$_};
	} keys %ARGV;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Config::Source::ARGV - L<Config::Data> fields from the command line

=head1 SYNOPSIS

	use Config::Source::ARGV;

	my $argv = Config::Source::ARGV->new
	my $config_hub = Config::Data->new($argv, $other_source);

Use a field

	sub do {
		my ($self, $c) = @_;
		print $c->handbag;
	}

And then on the command line, set it:

	my_app.pl --handbag=gucci

=head1 DESCRIPTION

This module is useful for getting some global keys set or perhaps overridden on
the command line.

=cut
