#!/usr/bin/perl

package Action::FlattenTree;
use base qw/Action/;

use strict;
use warnings;

use File::stat;

sub do {
	my $self = shift;
	my $c = shift;

	my $tree = $c->tree_file;
	my $out = $c->output;

	$c->logger->info("flattenning '$tree' into '$out' as a tab separated file");

	{
		open my $infh, "<", $tree
			or $c->logger->logdie("couldn't open '$tree': $!");
		open my $outfh, ">", $out
			or $c->logger->logdie("couldn't open '$out' for writing: $!");	

		local $, = "\t";
		local $\ = "\n";
	
		while (<$infh>){
			/^(\d{8})\s*(.*?)\s*$/
				or $c->logger->logdie("couldn't parse tree line '$_'");

			print $outfh $1, $2;
		}

		close $infh or $c->logger->logdie("couldn't close '$tree': $!");
		close $outfh or $c->logger->logdie("couldn't close '$out': $!");
	};

	$c->confirm($c);
}

sub verify {
	my $self = shift;
	my $c = shift;

	my $in = $c->tree_file;
	my $out = $c->output;

	# if the output doesn't exist
	return unless -e $out;

	-r $_ or $c->logger->logdie("'$_' is unreadable") for ($in, $out);

	# if the input has content but the output doesn't
	return if -s $in > 0 and -s $out == 0;
	
	# if the input is newer than the output
	stat($in)->mtime <= stat($out)->mtime;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::FlattenTree - 

=head1 SYNOPSIS

	use Action::FlattenTree;

=head1 DESCRIPTION

=cut
