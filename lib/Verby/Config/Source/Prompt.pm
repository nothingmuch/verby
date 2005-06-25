#!/usr/bin/perl

package Verby::Config::Source::Prompt;
use base qw/Verby::Config::Source/;

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

# this is a copy of ExtUtils::MakeMaker::prompt, hacked up for Verby
# it's stolen because EUMM takes 1 full second to load
sub prompt ($;$) {
	#my($mess, $def) = @_;
	my ($mess, $key) = @_; # no notion of a default - if it's there another config source knows about it already
	#Carp::confess("prompt function called without an argument") 
	Log::Log4perl::get_logger->logdie("prompt function called without an argument") 
		unless defined $mess;

	#my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;
	Log::Log4perl::get_logger->logdie("Can't prompt for '$key' - STDIN is not a terminal")
		unless -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;

	# defaults are no longer relevant
	#my $dispdef = defined $def ? "[$def] " : " ";
	#$def = defined $def ? $def : "";

	local $|=1;
	local $\;
	#print "$mess $dispdef";
	print $mess;

	#my $ans;
	#if ($ENV{PERL_MM_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
	#	print "$def\n";
	#}
	#else {
	#$ans = <STDIN>;
	#if( defined $ans ) {
	if (defined(my $ans = <STDIN>)) {
		chomp $ans;
		return $ans;
	}
	else { # user hit ctrl-D
		print "\n";
		Log::Log4perl::get_logger->logdie("Can't proceed - value for '$key' unknown");
	}
	#}

	#return (!defined $ans || $ans eq '') ? $def : $ans;
}

sub get_key {
	my $self = shift;
	my $key = shift;
	my $prompt = $self->{questions}{$key};

	Log::Log4perl::get_logger->logdie("Configuration key '$key' is unresolvable") unless $prompt;

	return prompt($prompt, $key);
}

sub prompt_all {
	my $self = shift;

	(tied %{ $self->{data} })->FETCH($_) for (keys %{ $self->{questions} });
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Config::Source::Prompt - 

=head1 SYNOPSIS

	use Verby::Config::Source::Prompt;

=head1 DESCRIPTION

=cut