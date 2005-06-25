#!/usr/bin/perl

package Log::Log4perl::Layout::SimpleLayout::Multiline;
use base qw/Log::Log4perl::Layout::SimpleLayout/;

use strict;
use warnings;

sub render {
	my $self = shift;
	my $output = $self->SUPER::render(@_);

	$output =~ /([A-Z]+ - )/;

	my $spaces = ' ' x length($1);
	$output =~ s/(\r?\n|\r)(?!$)/$1$spaces\t/g;

	$output;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Log::Log4perl::Layout::SimpleLayout::Multiline - 

=head1 SYNOPSIS

	use Log::Log4perl::Layout::SimpleLayout::Multiline;

=head1 DESCRIPTION

=cut
