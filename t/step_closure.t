#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 26;
use Test::MockObject;
use Test::Exception;

# TODO
# stringification

my $m; BEGIN { use_ok($m = "Verby::Step::Closure", "step") };

{
	my $t = Test::MockObject->new;

	isa_ok((my $s = step $t), $m);

	$t->set_false("verify");
	ok(!$s->is_satisfied, "step not satisfied");
	$t->called_ok("verify");

	$t->clear;

	$t->set_true("verify");
	ok($s->is_satisfied, "step satisfied");

	$t->clear;

	$t->mock("do");
	$s->do;
	$t->called_ok("do");
}

{
	dies_ok {
		step "BlahBlah::Action::Class::That::Does'nt::Exist";
	} "action class with require error is fatal";
}

{
	my $t = Test::MockObject->new;

	my ($before, $after);
	my $s = step $t, sub { $before++ }, sub { $after++ };

	foreach my $spec (
		[ "start", 1, 0 ],
		[ "pump", 0, 0 ],
		[ "finish", 0, 1 ],
	){
		$t->clear;
		($before, $after) = (0, 0);

		my ($method, $eb, $ea) = @{$spec};

		ok(!$s->can("$method"), "'can' lies when the underlying object can't do $method");
		
		$t->set_true($method);

		can_ok($s, $method);
		
		$s->$method;

		$t->called_ok($method);
		is($before, $eb, "before callback ".($eb ? "" : "not ")."called for '$method'");
		is($after, $ea, "after callback ".($ea ? "" : "not ")."called for '$method'");
	}
}

{
	# autoplural accessors and stuff
	my $t = Test::MockObject->new;
	my $s1 = step $t;
	my $s2 = step $t;
	my $s3 = step $t;

	is_deeply([ $s1->depends ], [ ], "no deps yet");
	$s1->add_deps($s2);
	is_deeply([ $s1->depends ], [ $s2 ], "dep appended");
	$s1->add_deps($s3);
	is_deeply([ $s1->depends ], [ $s2, $s3 ], "dep appended");
	$s1->depends($s2);
	is_deeply([ $s1->depends ], [ $s2 ], "dep replaced");
}
