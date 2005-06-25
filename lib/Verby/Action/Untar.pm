#!/usr/bin/perl

package Verby::Action::Untar;
use base qw/Verby::Action/;

use strict;
use warnings;

our $VERSION = '0.01';

use Archive::Tar;
use File::Spec;
use Sub::Override;

sub start {
	my $self = shift;
	my $c = shift;

	my $o = $self->_override_tar_error($c);

	my $tarball = $c->tarball;
	my $dest = $c->dest;

	# we're forking due to the chdir
	defined(my $pid = fork)
		or $c->logger->logdie("couldn't fork: $!");
	
	if ($pid){
		$c->pid($pid);
	} else {
		$c->logger->info("untarring '$tarball' into '$dest'");
		chdir $dest;
		Archive::Tar->extract_archive($tarball)
			or $c->logger->logdie("Archive::Tar->extract_archive did not return a true value");
		exit 0;
	}
}

sub finish {
	my $self = shift;
	my $c = shift;

	my $pid = $c->pid;

	$c->logger->debug("waiting for pid $pid");
	
	waitpid $pid, 0 or $c->logger->logdie("couldn't wait for $pid: $!");

	my $exit = ($? >> 8);
	my $level = ($exit ? "warn" : "info");
	$c->logger->$level("finished untarring " . $c->tarball . ": $pid exited with status $exit");

	$self->confirm($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

	my $o = $self->_override_tar_error($c);

	my $dest = $c->dest;

	my $tar_root;

	my $i;

	foreach my $file (Archive::Tar->list_archive($c->tarball)){
		$tar_root ||= (File::Spec->splitdir($file))[0];
		unless (-e File::Spec->catfile($dest, $file)){
			$c->logger->warn("file '$file' is missing from extracted directory") if $i; # it's ok only for the first file to be missing
			return undef;
		}
		$i++;
	}

	$c->src_dir(File::Spec->catdir($dest, $tar_root));

	return 1;
}

sub _override_tar_error {
	my $self = shift;
	my $c = shift;

	Sub::Override->new("Archive::Tar::_error" => sub { $c->logger->logdie(caller() . ": $_[1]") });
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Untar - Action to un-tar an archive

=head1 SYNOPSIS

	use Verby::Action::Untar;

=head1 DESCRIPTION

This Action, using L<Archive::Tar>, will untar a given archive.

=head1 METHODS 

=over 4

=item B<start>

=item B<finish>

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
