#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

my $m;
BEGIN { use_ok($m = "EERS::Step") }

can_ok($m, "new");
isa_ok(my $s = $m->new, $m);

can_ok($s, "id");
dies_ok { $s->id } "undef id is fatal";

can_ok($s, "execute");
dies_ok { $s->execute } "stub execute dies";

can_ok($s, "satisfied");
ok(!$s->satisfied, "step not satisfied by default");

can_ok($s, "depends");
is_deeply([ $s->depends ], [], "no dependencies by default");

ok(!$s->can("start"), "no default 'start'");
ok(!$s->can("finish"), "no default 'finish'");

{
	package SingletonStep;
	use base qw/EERS::Step Class::Singleton/;

	package StrongSingletonStep;
	use base qw/EERS::Step Class::StrongSingleton/;
}

isa_ok(my $single = SingletonStep->new, $m);
is($single->id, "singleton_step", "singletons have default IDs");

isa_ok(my $ssingle = StrongSingletonStep->new, $m);
is($ssingle->id, "strong_singleton_step", "strong singletons have default IDs");

is(SingletonStep->new("foo")->id, "foo", "but explicit id overrides it");
is(StrongSingletonStep->new("bar")->id, "bar", "... in both cases");

