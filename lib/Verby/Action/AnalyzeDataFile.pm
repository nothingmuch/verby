#!/usr/bin/perl

package Verby::Action::AnalyzeDataFile;
use Moose;

with qw/Verby::Action/;

use File::stat;
use Fcntl qw/SEEK_SET/;

sub do {
	my ( $self, $c ) = @_;

	my $file = $c->file;

	$c->logger->info("analyzing file '$file'");
	
	unless ($self->verify($c)){
		-e $file or $c->logger->logdie("File '$file' does not exist!");
		
		# stat the file
		$c->stat(my $stat = stat($file))
			or $c->logger->logdie("Couldn't stat file '$file': $!");

		open my $fh, "<", $file
			or $c->logger->logdie("Couldn't open file '$file': $!");

		if ($file !~ /\.tree$/){
			# read a chunk of the file
			my $b = $stat->blksize;
			$b = 2048 if $b < 2048;
			local $/ = \$b;
			local $_ = <$fh>;

			# guess the separator
			/([\t,\|:])/
				? $c->field_sep(local $, = $1)
				: $c->logger->logdie("Can't guess field separator");

			(/(\015\012)/ || /([\r\n])/)
				? $c->line_sep(local $/ = $1)
				: $c->logger->logdie("Can't guess line separator");

			# now that we know the separators, read a line
			seek $fh, 0, SEEK_SET;

			# and count the number of columns
			my @cols = split($,, scalar <$fh>);
			$c->columns(scalar @cols);
		} else {
			$c->is_tree_file(1);	
		}

		close $fh;
	}

	$self->confirm($c);
}

sub verify {
	my ( $self, $c ) = @_;

	defined $c->stat;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::AnalyzeDataFile - Analyze a text file containing delimiter
separated data.

=head1 SYNOPSIS

	use Verby::Action::AnalyzeDataFile;

=head1 DESCRIPTION

=cut
