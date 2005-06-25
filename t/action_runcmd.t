#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::MockObject;
use Hash::AsObject;
use Test::Exception;

my $m; BEGIN { use_ok($m = "Verby::Action::RunCmd") };

isa_ok(my $a = $m->new, $m);

my $c = Hash::AsObject->new;
my $logger = Test::MockObject->new;

$c->logger($logger);
$logger->set_true($_) for qw/info warn/;
$logger->mock("logdie" => sub { shift; die "@_" });

can_ok($a, "run");

lives_ok {
	$a->run($c, ["true"]);
} "exec of 'true'";

dies_ok {
	$a->run($c, ["false"]);
} "exec of 'false'";

{
	$logger->clear;

	my $in = <<FOO;
line 1
foo
bar
FOO

	my ($out, $err) = $a->run($c, [qw/wc -l/], { in => \$in });
	like($out, qr/^\s*\d+\s*$/, "output of wc -l looks sane");
	ok(!$err, "no stderr");
	ok(!$logger->called("warn"), "no warnings logged");
}

{
	$logger->clear;
	my $str = "foo";
	my ($out, $err) = $a->run($c, [qw/sh -c/, "echo $str 1>&2"]);
	chomp($err);
	is($err, $str, "stderr looks good");
	$logger->called_ok("warn");
}

{
	$logger->clear;
	my $e = "blah\n";
	my $o = "gorch\n";
	my $init = sub { warn $e; print STDOUT $o };
	my ($out, $err) = $a->run($c, ["true"], { init => $init });
	is($out, $o, "init invoked and outputted to stdout");
	is($err, $e, "... and stderr");
}
