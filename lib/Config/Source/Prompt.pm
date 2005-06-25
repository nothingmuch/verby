#!/usr/bin/perl

package Config::Source::Prompt;
use base qw/Config::Source/;

use strict;
use warnings;

sub new {
	my $pkg = shift;
	my $questions = shift;
	my $options = shift;

	my $self = $pkg->SUPER::new;

	$self->{questions} = $questions;
	
	$self->prompt_all if ($options->{asap});

	$self;
}

sub get_key {
	my $self = shift;
	my $key = shift;
	my $prompt = $self->{questions}{$key};

	Log::Log4perl::get_logger->logdie("Can't prompt for '$key' - unknown key") unless $prompt;
	Log::Log4perl::get_logger->logdie("Can't prompt for '$key' - STDIN is not a terminal") unless -t STDIN;

	local $| = 1;
	print $prompt;
	chomp(my $value = <STDIN>);

	return $value;
}

sub prompt_all {
	my $self = shift;

	(tied %{ $self->{data} })->FETCH($_) for (keys %{ $self->{questions} });
}

__PACKAGE__

__END__

=pod

=head1 NAME

Config::Source::Prompt - 

=head1 SYNOPSIS

	use Config::Source::Prompt;

=head1 DESCRIPTION

=cut
