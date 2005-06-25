#!/usr/bin/perl

package Verby::Action::Mysql::DoSql;
use base qw/Verby::Action/;

use strict;
use warnings;

our $VERSION = '0.01';

sub do {
	my $self = shift;
	my $c = shift;

	my $dbh = $c->dbh;

	local $dbh->{PrintError} = 0;
	local $dbh->{RaiseError} = 0;
	local $dbh->{HandleError} = sub { $c->logger->logdie(shift(@_) . " $self " . Data::Dumper::Dumper($c->data)) };

	$self->do_sql($c);

	$self->confirm($c);
}

sub do_sql {
	my $self = shift;
	my $c = shift;

	my $dbh = $c->dbh;
	my $sql = $c->sql;

	$dbh->do($sql);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Mysql::DoSql - 

=head1 SYNOPSIS

	use Verby::Action::Mysql::DoSql;

=head1 DESCRIPTION

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>
stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
