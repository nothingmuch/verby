

package Step::Async;
use base qw/Step::Simple/;

use strict;
use warnings;

sub start {
	my $self = shift;
	$self->{started}++;
	$self->log_event("started");
}

sub finish {
	my $self = shift;
	die "not started" unless $self->{started} and $self->{started} == 1;
	$self->log_event("finished");
}

__PACKAGE__

__END__

=pod

=head1 NAME

Step::Async - A mock installation step implementing start and finish.

=head1 SYNOPSIS

	use Step::Async;

	my $s = Step::Async->new(id => "id", log => []);

=head1 DESCRIPTION

Used in the test code.

=head1 METHODS

=over 4

=item start

Logs the 'started' event.

=item finish

Dies unless 'start' has been called 1 time beforehand.

Logs the 'finished' event.

=back

=cut
