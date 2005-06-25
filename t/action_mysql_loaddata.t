#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Plan;
use Test::MockObject;
use Test::Deep;
use Test::Exception;

use File::Temp qw/tempfile/;
use Fcntl qw/SEEK_SET/;

use DBI;

my $dbh;
BEGIN { plan tests => 14, sub { $dbh = DBI->connect("dbi:mysql:test"); $dbh } }

my $m;
BEGIN { use_ok($m = "Action::Mysql::LoadDataFile") }

# clear the DB a bit
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;
$dbh->do("drop table if exists foo");

my $future = time + 3;
my $past = time - 3;


my ($fh, $tempfile) = tempfile(UNLINK => 1);
chmod 0777, $tempfile;

syswrite $fh, "1,foo\n4,bar\n"; # don't bother with flushing

utime $future, $future, $tempfile;

my $c = Test::MockObject->new;
$c->set_always(dbh => $dbh);
$c->set_always(table => "foo");
$c->set_always(file => $tempfile);
$c->set_always(logger => Test::MockObject->new);
$c->logger->mock(logdie => sub { shift; die "@_" });
$c->logger->mock(warn => sub { shift; warn "@_" });
$c->logger->set_true($_) for qw/info warn debug/;

isa_ok(my $a = $m->new, $m);
isa_ok($a, "Action");

ok(!$a->verify($c), "verify is false when no table exists");

$dbh->do("create table foo (one integer, two varchar(10))");

ok(!$a->verify($c), "verify false after table created too");

utime $past, $past, $tempfile;

lives_ok { $a->do($c) } "action->do doesn't die";
ok($a->verify($c), "verification successful");

cmp_deeply(
	$dbh->selectall_arrayref("select * from foo"),
	[ [qw/1 foo/], [qw/4 bar/] ],
	"data was loaded",
);


sysseek $fh, 0, SEEK_SET;
syswrite $fh, "2\tgorch\r\n3\tbaz\r\n";
sleep 1;

ok(!$a->verify($c), "table invalidated after change to file");

lives_ok { $a->do($c) } "action->do doesn't die";
ok($a->verify($c), "verification successful");

cmp_deeply(
	$dbh->selectall_arrayref("select * from foo"),
	[ [qw/2 gorch/], [qw/3 baz/] ],
	"data was loaded",
);

$c->set_always(file => "/this/file/does_not/exist_at_alllll_NONONNO");
dies_ok { $a->do($c) } "can't load if file doesn't exist";

$c->set_always(file => $tempfile);
$dbh->do("drop table foo");
dies_ok { $a->do($c) } "can't load if table doesn't exist";
