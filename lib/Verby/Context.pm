#!/usr/bin/perl

package Verby::Context;
use base qw/Config::Data::Mutable/;

use strict;
use warnings;

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

It is a mutable L<Config::Data> that derives from the global context.

=head1 EXAMPLE USAGE

See the annotated F<scripts/module_builder.pl> for how a context is used in
practice.

=head1 THE LOGGER FIELD

	$c->logger;

will delegate to L<Log::Log4perl/get_logger>, sending it a nice string for a
category.

The category is the class of the caller, concatenated a stringification of the
object if the object can stringify.

=cut
