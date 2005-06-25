#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
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
{
	package My::Action;
	use base qw/Action/;

	sub verify { $v }
}

my $o = My::Action->new;

lives_ok { $o->confirm } "confirm when verified";

$v = 0;
dies_ok { $o->confirm } "confirm when verification failed";

