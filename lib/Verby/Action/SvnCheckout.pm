#!/usr/bin/perl

package Verby::Action::SvnCheckout;
use base qw/Verby::Action::RunCmd/;

use strict;
use warnings;

our $VERSION = '0.01';

use File::Spec;

sub do {
	my $self = shift;
	my $c = shift;

	$self->run($c, ["svn", $c->source, $c->dest]);

	$self->confirm;
}

sub verify {
	my $self = shift;
	my $c = shift;

	my $wd = $c->dest;

	return unless -d $wd
		and -d File::Spec->catdir($wd, ".svn")
		and $self->run($c, [qw/svn up/], undef, sub { chdir $wd });
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::SvnCheckout - 

=head1 SYNOPSIS

	use Verby::Action::SvnCheckout;

=head1 DESCRIPTION

=head1 METHODS 

=over 4

=item B<do>

=item B<verify>

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
