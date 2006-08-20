#!/usr/bin/perl

package Verby::Action::Make;
use Moose;

extends qw/Verby::Action::RunCmd/;

sub do {
	my ( $self, $c ) = @_;

	my $wd = $c->workdir;
	my @targets = (($c->target || ()), @{ $c->targets || [] });

	$c->is_make_test(1) if "@targets" eq "test";

	$self->create_poe_session(
		c   => $c,
		cli => [qw/make -C/, $wd, @targets],
	);
}

sub finished {
	my ( $self, $c ) = @_;

	$c->done(1);

	my $out = $c->stdout;
	chomp($out);
	$c->logger->info("test output:\n$out") if $c->is_make_test;

	$self->confirm($c);
}

sub log_extra {
	my ( $self, $c ) = @_;

	" in " . $c->workdir;
}

sub verify { $_[1]->done }

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Make - Action to run 'make' on the command line

=head1 SYNOPSIS

	use Verby::Action::Make;

=head1 DESCRIPTION

This class inherits from L<Verby::Action::RunCmd> to provide the ability to run 'make' on the command line.

=head1 METHODS 

=over 4

=item B<start>

=item B<finish>

=item B<verfiy>

=item B<log_extra>

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
