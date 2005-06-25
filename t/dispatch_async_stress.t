#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Deep;
use Test::MockObject;
use List::MoreUtils qw/uniq/;
use Config::Data;

my $steps = 1000;

my $m;
BEGIN { use_ok($m = "Verby::Dispatcher") }

my @items = map { Test::MockObject->new } 1 .. $steps;
foreach my $meth (qw/is_satisfied provides_cxt/){
	$_->set_always($meth => (rand > rand(1.5))) for @items;
}

$_->set_list(depends => ()) for @items;

# a complicated but non recursive dep tree
foreach my $slice (map { $_ * 10 }  1 .. (($steps / 10) - 1)) {
	my @dependant = grep { rand > rand } @items[$slice-10 .. $slice-1];
	my @depended = @items[$slice .. $slice+9];

	foreach my $item (@dependant){
		$item->set_list(depends => grep { rand > .8 } @depended)
	}
}

my @finished = grep { $_->is_satisfied } @items;
$_->mock(finish => sub { push @finished, $_[0] }) for @items;
$_->set_true("start") for @items;

foreach my $item (@items){
	my $i = rand(rand(10));
	$item->mock(pump => sub { --$i > 1 });
}

isa_ok(my $d = $m->new, $m);

my $cfg = Config::Data->new;
$cfg->data->{logger} = Test::MockObject->new;
$d->config_hub($cfg);

$cfg->logger->set_true($_) for qw/info debug/;
#$cfg->logger->mock($_ => sub { warn "@_\n" }) for qw/info debug/;

can_ok($d, "add_steps");
$d->add_steps(@items);

is(() = $d->step_set->members, $steps, "$steps random steps were added to dispatcher");

can_ok($d, "do_all");
my $t1 = times;
$d->do_all;
my $t2 = times;

my $all_satisfied = 1;
$all_satisfied &&= $d->is_satisfied($_) for @items;
ok($all_satisfied, sprintf('%d random steps resolved in %.2f seconds', $steps, ($t2-$t1)));

cmp_deeply([ sort @finished ], [ sort @items ], "all steps marked finished"); # bag is too slow
