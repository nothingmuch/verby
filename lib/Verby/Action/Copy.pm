#!/usr/bin/perl

package Verby::Action::Copy;
use base qw/Verby::Action::RunCmd/;

use strict;
use warnings;

our $VERSION = '0.01';

use File::Rsync;

sub start {
	my $self = shift;
	my $c = shift;

	my $source = $c->source;
	my $dest = $c->dest;

	$c->logger->info("copying tree from '$source' to '$dest'");

	my $r = File::Rsync->new({ archive => 1, delete => 1 }) or $c->logger->logdie("couldn't create rsync obj");
	my $cmd = $r->getcmd({ src => $source, dest => $dest }) or $c->logger->logdie("couldn't determine rsync command to run");
	
	$self->cmd_start($c, $cmd, { log_stdout => 1 });
}

sub finish {
	my $self = shift;
	my $c = shift;

	$c->done(1);
	$self->SUPER::finish($c);
}

sub verify {
	$_[1]->done;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Copy - Action to copy a directory tree to from one location to
another using rsync.

=head1 SYNOPSIS

	use Verby::Step::Closure qw/step/;
	step "Verby::Action::Copy" => sub {
		my ($self, $c) = @_;
		$c->source("/path/to/copy/from");
		$c->dest("/path/to/copy/to");
	}

=head1 DESCRIPTION

This module uses L<File::Rsync> to copy a directory tree to from one location
to another.

=head1 METHODS 

=over 4

=item B<start>

=item B<finish>

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
