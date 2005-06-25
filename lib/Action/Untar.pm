#!/usr/bin/perl

package Action::Untar;
use base qw/Action/;

use strict;
use warnings;

use Archive::Tar;
use File::Spec;

sub do {
	my $self = shift;
	my $c = shift;

	my $tarball = $c->tarball;
	my $dest = $c->dest;

	$c->logger->note("unpacking '$tarball' into '$dest'");

	# we're forking due to the chdir
	die "couldn't fork: $!" unless defined(my $pid = fork);
	
	if ($pid){
		waitpid $pid, 0;
	} else {
		chdir $dest;
		Archive::Tar->extract_archive($tarball);
		exit;
	}

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
			my $level = $i ? "note" : "warn";
			$c->logger->$level("file '$file' is missing from extracted directory");
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

Action::Untar - 

=head1 SYNOPSIS

	use Action::Untar;

=head1 DESCRIPTION

=cut
