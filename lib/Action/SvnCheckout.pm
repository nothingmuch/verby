#!/usr/bin/perl


package Action::SvnCheckout;
use base qw/Action/;

use strict;
use warnings;

use IPC::Run qw/run/;
use Fatal qw/run/;
use File::Spec;

sub do {
	my $self = shift;
	my $c = shift;

	my $from = $c->source;
	my $to = $c->dest;
	my $svn = $c->svn_exe;

	run [$svn, $from, $to], \(my ($in, $out, $err));

	$c->error($err);
	
	$self->confirm;
}

sub verify {
	my $self = shift;
	my $c = shift;

	return unless -d $c->dest;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Action::SvnCheckout - 

=head1 SYNOPSIS

	use Action::SvnCheckout;

=head1 DESCRIPTION

=cut
