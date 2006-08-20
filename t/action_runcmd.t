#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::MockObject;
use Hash::AsObject;
use Test::Exception;

use POE;

my $m; BEGIN { use_ok($m = "Verby::Action::RunCmd") };

isa_ok(my $a = $m->new, $m);

my $logger = Test::MockObject->new;
$logger->mock($_ => sub { shift; warn "@_"; } ) for qw/info warn/;
$logger->mock("logdie" => sub { shift; die "@_" });

can_ok($a, "create_poe_session");

sub run_poe (&) {
	my $code = shift;

	eval {
		POE::Session->create(
			inline_states => {
				_start => sub { $code->(); return },
				_stop  => sub { },
				_child => sub { },
			},
		);
		$poe_kernel->run;
	};
}

SKIP: {
	my $true = "/usr/bin/true";
	skip 1, "no true(1)" unless -x $true;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	run_poe { $a->create_poe_session( c => $c, cli => [$true]) };
	ok( !$@, "exec of true" ) || diag "cought: $@";
}

SKIP: {
	my $false = "/usr/bin/false";
	skip 1, "no false(1)" unless -x $false;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	run_poe { $a->create_poe_session( c => $c, cli => [$false]) };
	ok( $@, "exec of 'false'" ) || diag "no exception for false";
}

{
	my $wc = "/usr/bin/wc";
	skip 4, "no wc(1)" unless -x $wc;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	my $in = <<FOO;
line 1
foo
bar
FOO

	run_poe { $a->create_poe_session( c => $c, cli => [$wc, "-l"], in => \$in ) };
	ok( !$@, "wc -l didn't die" ) || diag($@);
	use Data::Dumper;
	warn Dumper( $c );
	my ($out, $err) = ( $c->stdout, $c->stderr );
	like($out, qr/^\s*\d+\s*$/, "output of wc -l looks sane");
	is( ($err || ""), "", "no stderr");
	ok(!$logger->called("warn"), "no warnings logged");
}

{
	my $sh = "/bin/sh";
	skip 3, "no sh(1)" unless -x $sh;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	my $str = "foo";

	run_poe { $a->create_poe_session( c => $c, cli => [$sh,  "-c", "echo $str 1>&2"]) };
	my ($out, $err) = ( $c->stdout, $c->stderr );

	chomp($err);
	is($err, $str, "stderr looks good");
	$logger->called_ok("warn");
}

{
	my $true = "/usr/bin/true";
	skip 2, "no true(1)" unless -x $true;

	$logger->clear;
	my $c = Hash::AsObject->new;
	$c->logger($logger);

	my $e = "blah\n";
	my $o = "gorch\n";
	my $init = sub { warn $e; print STDOUT $o };

	run_poe { $a->create_poe_session( c => $c, cli => [$true], init => $init ) };
	my ($out, $err) = ( $c->stdout, $c->stderr );

	$_ ||= '', chomp for $out, $err, $e, $o;

	is($out, $o, "init invoked and outputted to stdout");
	is($err, $e, "... and stderr");
}
