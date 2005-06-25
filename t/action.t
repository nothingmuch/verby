#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use Test::MockObject;

my $m;
BEGIN { use_ok($m = "Verby::Action") };

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
	use base qw/Verby::Action/;

	sub verify { push @args, [ @_ ]; $v }
}

my $o = My::Action->new;

my $logger = Test::MockObject->new;
$logger->mock(logdie => sub { shift; die "@_" });

my $foo = Test::MockObject->new;
$foo->set_always(logger => $logger);
$foo->set_false("error");
lives_ok { $o->confirm($foo) } "confirm when verified";
is_deeply(\@args, [ [ $o, $foo ] ], "confirm proxied args");

$logger->clear;

$v = 0;
@args = ();
my $bar = Test::MockObject->new;
$bar->set_always(logger => $logger);
$bar->set_false("error");
dies_ok { $o->confirm($bar) } "confirm when verification failed";
is_deeply(\@args, [ [ $o, $bar ] ], "confirm proxied args");

$logger->called_ok("logdie");

