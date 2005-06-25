#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 16;
use Test::Exception;

use DBI;
use Test::MockObject;
use Test::MockObject::Extends;
use Hash::AsObject;
use Sub::Override;

my $m; BEGIN { use_ok($m = "Action::MysqlCreateDB") }

my $dbh = DBI->connect("dbi:Mock:", {});

$INC{"DBI/db.pm"} = 1;
my $dbh_dsns = Test::MockObject::Extends->new($dbh);

$dbh_dsns->set_always( data_sources => qw/dbi:Mock:foo/ );
$dbh_dsns->mock(do => sub {
	my $self = shift;
	
	$self->set_list( data_sources => qw/dbi:Mock:foo dbi:Mock:bar/ );
	$self->unmock("do");
	$self->do(@_);
});

my $logger = Test::MockObject->new;
$logger->set_true("note");

my $c = Hash::AsObject->new;
$c->logger($logger);
$c->dbh($dbh_dsns);
$c->db_name("foo");

isa_ok(my $a = $m->new, $m);

ok($a->verify($c), "db foo exists");
lives_ok { $a->confirm($c) } "confirm lives";

$dbh_dsns->called_ok("data_sources");

$c->db_name("bar");

ok(!$a->verify($c), "db bar does not exist");
dies_ok { $a->confirm($c) } "confirm dies";

ok(!$logger->called("note"), "no log message noted yet");

my $history = $dbh->{mock_all_history};
is(@$history, 0, "no history yet");


lives_ok { $a->do($c) } "create lives";

is(@$history, 1, "one statment in history");
my $sth = $history->[0];
like($sth->statement, qr/^\s*create\s+database\s+\?\s*;?/i, "create db sql");
is($sth->bound_params->[0], "bar", "bound param was 'bar'");

ok($a->verify($c), "db bar now exists");
lives_ok { $a->confirm($c) } "confirm lives";

$logger->called_ok("note");
