#!/usr/bin/perl
# TODO
# this file needs a bit of cleanup;

use strict;
use warnings;

use Test::More;
use Test::Plan;
use Test::MockObject;
use Test::Deep;
use Test::Exception;
use Hash::AsObject;

use File::Temp qw/tempfile/;
use Fcntl qw/SEEK_SET/;
use File::stat;

my $dbh;
BEGIN { plan tests => 15,
	need_module("DBI"),
	need_module("DBD::mysql"),
	sub { $dbh = DBI->connect("dbi:mysql:test"); $dbh }, # try to connect
}

my $m;
BEGIN { use_ok($m = "Verby::Action::Mysql::LoadDataFile") }

# clear the DB a bit
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;
$dbh->{PrintWarn} = 0;
$dbh->do("drop table if exists foo");

my ($fh, $tempfile) = tempfile(UNLINK => 1);
chmod 0777, $tempfile;
syswrite $fh, "1,foo\n4,bar\n"; # don't bother with flushing

my $c = Hash::AsObject->new;
$c->dbh($dbh);
$c->table("foo");
$c->file($tempfile);
$c->columns(2);
$c->field_sep(",");
$c->line_sep("\n");
$c->stat(my $stat = stat($tempfile));
$c->logger(Test::MockObject->new);
$c->logger->mock(logdie => sub { shift; die "@_" });
#$c->logger->mock($_ => sub { shift; warn "@_" }) for qw/info warn debug/;
$c->logger->set_true($_) for qw/info warn debug/;

isa_ok(my $a = $m->new, $m);
isa_ok($a, "Verby::Action");

$stat->mtime(time + 3);

ok(!$a->verify($c), "verify is false when no table exists");

$dbh->do("create table foo (one integer, two varchar(10))");

ok(!$a->verify($c), "verify false after table created too");

$stat->mtime(time - 3);

lives_ok { $a->do($c) } "action->do doesn't die";
ok($a->verify($c), "verification successful");

cmp_deeply(
	$dbh->selectall_arrayref("select * from foo"),
	[ [qw/1 foo/], [qw/4 bar/] ],
	"data was loaded",
);

sysseek $fh, 0, SEEK_SET;
syswrite $fh, "2\tgorch\r\n3\tbaz\r\n4\tding\r\n";

$stat->mtime(time + 3);

$c->field_sep("\t");
$c->line_sep("\r\n");

ok(!$a->verify($c), "table invalidated after change to file");

$stat->mtime(time - 3);

lives_ok { $a->do($c) } "action->do doesn't die";
ok($a->verify($c), "verification successful");

cmp_deeply(
	$dbh->selectall_arrayref("select * from foo"),
	[ [qw/2 gorch/], [qw/3 baz/], [qw/4 ding/] ],
	"data was loaded",
);

$c->file("/this/file/does_not/exist_at_alllll_NONONNO");
dies_ok { $a->do($c) } "can't load if file doesn't exist";

$c->file($tempfile);

$c->columns(3);
dies_ok { $a->do($c) } "column numbers must match";

$dbh->do("drop table foo");
dies_ok { $a->do($c) } "can't load if table doesn't exist";

