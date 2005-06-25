#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

my $m;
BEGIN { use_ok($m = "Action") };

can_ok($m, "new");
isa_ok(my $a = $m->new, $m);

can_ok($m, "do");
dies_ok { $m->do } "'do' is a stub";

can_ok($m, "verify");
dies_ok { $m->do } "'verify' is a stub";

can_ok($m, "confirm");

my $v = 1;
my @args;
{
	package My::Action;
	use base qw/Action/;

	sub verify { push @args, [ @_ ]; $v }
}

my $o = My::Action->new;

lives_ok { $o->confirm("foo") } "confirm when verified";
is_deeply(\@args, [ [ $o, "foo" ] ], "confirm proxied args");

$v = 0;
@args = ();
dies_ok { $o->confirm("bar") } "confirm when verification failed";
is_deeply(\@args, [ [ $o, "bar" ] ], "confirm proxied args");

