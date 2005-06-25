#!/usr/bin/perl

package Verby::Action::Untar;
use base qw/Verby::Action/;

use strict;
use warnings;

use Archive::Tar;
use File::Spec;

sub start {
	my $self = shift;
	my $c = shift;

	my $tarball = $c->tarball;
	my $dest = $c->dest;

	# we're forking due to the chdir
	defined(my $pid = fork)
		or $c->logger->logdie("couldn't fork: $!");
	
	if ($pid){
		$c->pid($pid);
	} else {
		$c->logger->info("unpacking '$tarball' into '$dest'");
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

	my $exit = ($? & 0xff);
	my $level = ($exit ? "warn" : "info");
	$c->logger->$level("$pid exited with status $exit");

	$self->confirm($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

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

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Untar - 

=head1 SYNOPSIS

	use Verby::Action::Untar;

=head1 DESCRIPTION

=cut
