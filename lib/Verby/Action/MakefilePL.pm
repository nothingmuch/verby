#!/usr/bin/perl

package Verby::Action::MakefilePL;
use Moose;

extends qw/Verby::Action::RunCmd/;

use File::Spec;
use File::stat;

sub do {
	my ( $self, $c ) = @_;

	my $wd = $c->workdir;

	$self->create_poe_session(
		c    => $c, 
		cli  => [$^X, 'Makefile.PL'],
		init => sub { chdir $wd },
   	);
}

sub finished {
	my ( $self, $c ) = @_;

	$self->confirm( $c );
}

sub log_extra {
	my $self = shift;
	my $c = shift;

	" in " . $c->workdir;
}

sub verify {
	my $self = shift;
	my $c = shift;

	my $makefile = File::Spec->catfile($c->workdir, "Makefile");
	my $makefile_pl = File::Spec->catfile($c->workdir, "Makefile.PL");

	return -e $makefile && stat($makefile)->mtime >= stat($makefile_pl)->mtime;
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
