#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::MockObject;
use Test::Exception;

use File::Temp qw/tempfile/;
use File::Spec;
use Config::Data;

my $m; BEGIN { use_ok($m = "Action::Template") };

my ($outfh, $outfile) = tempfile(UNLINK => 1);

my $c = Config::Data->new;
%{ $c->data } = (
	template => \*DATA,
	output => $outfile,

	logger => Test::MockObject->new,

	foo => "blah",
);

$c->logger->set_true($_) for qw/info/;
$c->logger->mock(logdie => sub { shift; die "@_" });

isa_ok(my $a = $m->new, $m);

can_ok($a, "do");

ok(!$a->verify($c), "verify is false");

lives_ok { $a->do($c) } "template had no errors";

my $output = do { local $/; <$outfh> };
like($output, qr/foo='blah'/s, "output looks good");

__DATA__
foo bar gorch
foo='[% c.foo() %]'
ding ding ding

