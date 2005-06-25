#!/usr/bin/perl

package Step::PreSatisfied;
use base qw/Step::Simple/;

use strict;
use warnings;

sub satisfied { 1 }

__PACKAGE__

__END__

=pod

=head1 NAME

Step::PreSatisfied - A mock installation step for testing satisfied conditions.

=head1 SYNOPSIS

	use Step::PreSatisfied;

	my $step = Step::PreSatisfied->new("id");

=head1 DESCRIPTION

Used in the test code.

=head1 METHODS

=over 4

=item satisfied

Always return a true value.

=back

=cut
