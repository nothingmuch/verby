#!/usr/bin/perl

package Step;

use strict;
use warnings;

use Scalar::Util qw/weaken/;

sub new {
	my $pkg = shift;
	my $dispatcher = shift;

	my $self = bless { dispatcher => $dispatcher }, $pkg;
	weaken($self->{dispatcher});
}

sub depends {
	die "not implemented";
}

__PACKAGE__

__END__

=pod

=head1 NAME

Step - 

=head1 SYNOPSIS

	use Step;

=head1 DESCRIPTION

=cut
