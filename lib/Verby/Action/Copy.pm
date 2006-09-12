#!/usr/bin/perl

package Verby::Action::Copy;
use Moose;

with qw/Verby::Action::Run::Unconditional/;

use File::Rsync;

has rsync_path => (
	isa => "Str",
	is  => "rw",
	default => undef,
);

has rsync_options => (
	isa => 'HashRef',
	is  => "rw",
	default => sub { {} },
);

has rsync_object => (
	isa => "Object",
	is  => "rw",
	lazy => 1,
	default => sub { $_[0]->_make_rsync_object },
);

sub do {
	my ( $self, $c ) = @_;
	my ( $source, $dest ) = ( $c->source, $c->dest );

	my $cmd = $self->rsync_cli( $c );

	$c->logger->info("copying tree from '$source' to '$dest'");

	$self->create_poe_session(
		c          => $c,
		cli        => $cmd,
		log_stdout => 1,
	);
}

sub rsync_cli {
	my ( $self, $c ) = @_;
	my ( $source, $dest ) = ( $c->source, $c->dest );

	my $rsync_path = $self->rsync_path;

	my $r = $self->rsync_object || $c->logger->logdie("couldn't create rsync obj");

	return $r->getcmd({
		src  => $source,
		dest => $dest
	}) || $c->logger->logdie("couldn't determine rsync command to run");
}

sub _make_rsync_object {
	my $self = shift;

	return File::Rsync->new({
		archive => 1,
		delete  => 1,
		quiet   => 1,
		( defined($self->rsync_path) ? ( 'rsync-path' => $self->rsync_path ) : () ),
		%{ $self->rsync_options },
	});
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

=item B<do>

Runs rsync from C<< $c->source >> to C<< $c->dest >> unconditionally. Since
rsync has it's own verification logic this is still fairly fast.

=item B<rsync_cli>

Returns an array reference of the command line to use. Calls C<getcmd> on
C<rsync_object>.

=back

=head1 PARAMETERS

The following parameters are taken from the context object:

=over 4

=item B<source>

=item B<dest>

The rsync source/destination paths to use.

=back

=head1 FIELDS

The actions instance can contain additional configuration options.

=over 4

=item B<rsync_path>

When undef, this is handled by L<File::Rsync>. Otherwise you can provide an
alternate path for rsync.

=item B<rsync_options>

A hash reference with additional optiosn to override the defaults.

=item B<rsync_object>

This is a lazy field, that creates a L<File::Rsync> object based on the other
fields. You may override this with any object that can handle L<File::Rsync>'s
C<getcmd> method.

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we
will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to
COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

L<File::Rsync>, L<Verby::Action::Run>

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005, 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
