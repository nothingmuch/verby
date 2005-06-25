#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";

use Test::More tests => 11;
use Test::Deep;
use List::MoreUtils qw/uniq/;

use Step::Source;
use Step::Utils;
use Step::Async;

my $m;
BEGIN { use_ok($m = "EERS::Installer::Dispatch") };

my ($log, @items) = mk_mock_steps(4, "Step::Async");

$items[1]->depend_on(@items[0, 2]);
$items[3]->depend_on($items[1]);

my $src = Step::Source->new(\@items);

isa_ok(my $d = $m->new($src), $m);
can_ok($d, "dispatch");

$d->dispatch;

is(@$log, 8, "4 steps executed, in 8 events");
is((uniq map { $_->{obj} } @$log), 4, "each step is distinct");

my @finished = objs filter_event "finished", @$log;

cmp_deeply([ @finished[0,1] ], bag(@items[0,2]), "first two steps are in either order");
cmp_deeply([ @finished[2,3] ], [ @items[1,3] ], "last steps are stricter");

for (@items){
	ok($d->is_satisfied($_), $_->id . " is marked as satisfied");
}

