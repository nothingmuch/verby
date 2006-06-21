#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;
use Test::MockObject;
use Test::Exception;
use Hash::AsObject;

use File::Temp qw/tempfile/;
use Fcntl qw/SEEK_SET/;

my $m;
BEGIN { use_ok($m = "Verby::Action::AnalyzeDataFile") }

my $logger = Test::MockObject->new;
$logger->mock(logdie => sub { shift; die "@_" });
$logger->set_true($_) for qw/info warn debug/;

isa_ok(my $a = $m->new, $m);
isa_ok($a, "Verby::Action");

{
	my ($fh, $tempfile) = tempfile(UNLINK => 1);
	syswrite $fh, "1,foo\n4,bar\n"; # don't bother with flushing

	my $c = Hash::AsObject->new;
	$c->file($tempfile);
	$c->logger($logger);

	ok(!$a->verify($c), "verify fails when not yet analyzed");

	lives_ok { $a->do($c) } "action->do doesn't die";
	ok($a->verify($c), "verification successful");

	is($c->field_sep, ",", "field separator");
	is($c->line_sep, "\n", "line separator");
	is($c->columns, 2, "column count");
	isa_ok($c->stat, "File::stat", '$c->stat');
	
	$logger->called_ok("info");
	ok(!$logger->called("warn"), "no warnings though");
	ok(!$logger->called("logdie"), "... or fatals");
}

$logger->clear;

{
	my ($fh, $tempfile) = tempfile(UNLINK => 1);
	syswrite $fh, "2\tgorch\toink\015\0123\tbaz\t60\015\012";

	my $c = Hash::AsObject->new;
	$c->file($tempfile);
	$c->logger($logger);

	ok(!$a->verify($c), "verify fails when file not yet analyzed");

	lives_ok { $a->do($c) } "action->do doesn't die";
	ok($a->verify($c), "verification successful");

	is($c->field_sep, "\t", "field separator");
	is($c->line_sep, "\015\012", "line separator");
	is($c->columns, 3, "column count");
}

$logger->clear;

{
	my $c = Hash::AsObject->new;
	$c->file("/this/file/does_not/exist_at_alllll_NONONNO");
	$c->logger($logger);

	dies_ok { $a->do($c) } "dies if file doesn't exist";
	$logger->called_ok("logdie");
}

$logger->clear;

{
	my ($fh, $tempfile) = tempfile(UNLINK => 1);
	syswrite $fh, "2\tgorch\toink\015\0123\tbaz\t60\015\012";
	chmod 0, $tempfile;

	my $c = Hash::AsObject->new;
	$c->file($tempfile);
	$c->logger($logger);

	dies_ok { $a->do($c) } "dies on unreadable file";
	$logger->called_ok("logdie");
}

