#!/usr/bin/perl

package Verby::Context;
use Moose;

extends qw/Verby::Config::Data::Mutable/;

our $VERSION = "0.03";

use Log::Log4perl ();
use Devel::Caller::Perl ();
require overload;

sub logger {
	my $self = shift;

	return $self->SUPER::logger(@_) || $self->_get_logger();
}

sub _get_logger {
	my $self = shift;
	my $obj; $obj ||= (Devel::Caller::Perl::called_args($_))[0] for (2, 1);

	my $class = ref $obj || $obj;
	my $str = (overload::Method($obj, '""') ? "::$obj" : ""); # if it knows to stringify, get that too

	return Log::Log4perl::get_logger("$class$str");
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Context - A sort of scratchpad every L<Verby::Step> gets from
L<Verby::Dispatcher>.

=head1 SYNOPSIS

	sub do {
		my $self = shift;
		my $context = shift;

		print $context->rockets; # get a value
		$context->milk("very"); # set a value
	}

=head1 DESCRIPTION

A context has two roles in L<Verby>. The first is to control what a
L<Verby::Action> will do, by providing it with parameters, and the other is to
share variables that the action sets, so that other steps may have them too.

It is a mutable L<Verby::Config::Data> that derives from the global context.

=head1 METHODS

=over 4

=item B<logger>

=back

=head1 EXAMPLE USAGE

See the annotated F<scripts/module_builder.pl> for how a context is used in
practice.

=head1 THE LOGGER FIELD

	$c->logger;

will delegate to L<Log::Log4perl/get_logger>, sending it a nice string for a
category.

The category is the class of the caller, concatenated a stringification of the
object if the object can stringify.

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005, 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
