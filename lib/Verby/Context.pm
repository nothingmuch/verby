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

Verby::Context - 

=head1 SYNOPSIS

	use Verby::Context;

=head1 DESCRIPTION

=cut
