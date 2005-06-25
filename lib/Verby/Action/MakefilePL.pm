#!/usr/bin/perl

package Verby::Action::MakefilePL;
use base qw/Verby::Action::RunCmd/;

use strict;
use warnings;

our $VERSION = '0.01';

use File::Spec;

sub start {
	my $self = shift;
	my $c = shift;

	my $wd = $c->workdir;

	$self->cmd_start($c, [qw/perl Makefile.PL/], { init => sub { chdir $wd } });
}

sub log_extra {
	my $self = shift;
	my $c = shift;

	" in " . $c->workdir;
}

sub verify {
	my $self = shift;
	my $c = shift;

	-e File::Spec->catfile($c->workdir, "Makefile");
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::MakefilePL - Action to run 'perl Makefile.PL' on the command line

=head1 SYNOPSIS

	use Verby::Action::MakefilePL;

=head1 DESCRIPTION

This class inherits from L<Verby::Action::RunCmd> to provide the ability to run 
'perl Makefile.PL' on the command line.

=head1 METHODS 

=over 4

=item B<start>

=item B<log_extra>

=item B<verfiy>

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
