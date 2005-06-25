#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;
use Test::Deep;
use Test::MockObject;
use List::MoreUtils qw/uniq/;
use Config::Data;

my $m;
BEGIN { use_ok($m = "Dispatcher") }

my @items = map { Test::MockObject->new } 1 .. 4;
$_->set_always(is_satisfied => undef) for @items;
$_->set_list(depends => ()) for @items;
$items[1]->set_list(depends => @items[0, 2]);
$items[3]->set_list(depends => ($items[1]));

my @log;
foreach my $event (qw/start finish/){
	$_->mock($event => sub { push @log, [ $event, @_ ] }) for @items;
}

isa_ok(my $d = $m->new, $m);

my $cfg = Config::Data->new;
$cfg->data->{logger} = Test::MockObject->new;
$d->config_hub($cfg);

can_ok($d, "add_step");
$d->add_step($_) for @items;

isa_ok($d->step_set, "Set::Object");
cmp_deeply([ $d->step_set->members ], bag(@items), "step set contians items");

isa_ok($d->satisfied_set, "Set::Object");
cmp_deeply([ $d->satisfied_set->members ], [], "selected set contains no items");

can_ok($d, "do_all");
$d->do_all;

ok($d->is_satisfied($_), "step satisfied") for @items;

foreach my $event (qw/start finish/){
	$_->called_ok($event) for @items;
}

is(@log, 8, "4 steps executed, in 8 events");
is((uniq map { $_->[1] } @log), 4, "each step is distinct");

my @finished = map { $_->[1] } grep { $_->[0] eq "finish" } @log;

cmp_deeply([ @finished[0,1] ], bag(@items[0,2]), "first two steps are in either order");
cmp_deeply([ @finished[2,3] ], [ @items[1,3] ], "last steps are stricter");

