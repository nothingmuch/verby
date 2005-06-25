#!/usr/bin/perl

# no package, no exports.
# this is in main.

sub objs {
	map { $_->{obj} } @_;
}

sub mk_mock_steps {
	my $n = shift;
	my $class = shift || "Step::Simple";
	die "$class is not a subclass of Step::Simple" unless $class->isa("Step::Simple");
	my $log = [];
	my $i = 0;
	$log, map { $class->new(id => ("s" . $i++), log => $log) } 1 .. $n;
}

sub filter_event {
	my $type = shift;
	grep { $_->{type} eq $type } @_;
}

1;

__END__

=pod

=head1 NAME

Step::Utils - testing functions used to create or query steps and logged
events.

=head1 SYNOPSIS

	use Step::Util;
	my @items = mk_mock_steps($howmany);

=head1 EXPORTING

This package does not export, because I'm lazy. Instead, it's methods are just
declared in C<main::>. Since tests are the ones who are supposed to use it
anyway, it doesn't really matter.

=head1 FUNCTIONS

=over 4

=item mk_mock_steps $howmany, $?class = "Step::Simple

Creates $howmany steps of class $class, with IDs set as C<qw/s0 s1 .../>.

=item objs *@events

Given a list of events (L<Step::Simple/log_event>) extract the objects that
recorded them.

=item filter_event $type, *@events

Return only the events of a certain type (e.g. C<executed>, C<finished>).

=back

=cut
