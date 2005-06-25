#!/usr/bin/perl

package Context;
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
	my $obj = (Devel::Caller::Perl::called_args(2))[0];
	
	my $class = ref $obj || $obj; # get it's class
	my $str = (overload::Method($obj, '""') ? "::$obj" : ""); # if it knows to stringify, get that too

	return Log::Log4perl::get_logger("$class$str");
}

__PACKAGE__

__END__

=pod

=head1 NAME

Context - 

=head1 SYNOPSIS

	use Context;

=head1 DESCRIPTION

=cut
