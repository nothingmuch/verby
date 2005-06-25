#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";

use Test::More tests => 10;
use Test::Deep;
use List::MoreUtils qw/uniq/;

use Step::Source;
use Step::Utils;
use Step::Simple;
use Step::PreSatisfied;

my $m;
BEGIN { use_ok($m = "EERS::Installer::Dispatch") };

my ($log, @items) = mk_mock_steps(4);

$items[1]->depend_on(@items[0, 2]);
$items[3]->depend_on($items[1]);

my $src = Step::Source->new(\@items);

bless $items[$_], "Step::PreSatisfied" for (0, 2);

isa_ok(my $d = $m->new($src), $m);

can_ok($d, "dispatch");
$d->dispatch;

is(@$log, 2, "2 steps executed");
is((uniq objs @$log), 2, "each step is distinct");

cmp_deeply([ objs @$log ], [ @items[1,3] ], "execution log order is correct");

for (@items){
	ok($d->is_satisfied($_), $_->id . " is marked as satisfied");
}

