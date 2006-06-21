#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Plan;
use Test::Exception;

use Test::MockObject;
use Test::MockObject::Extends;
use Hash::AsObject;
use Sub::Override;

BEGIN { plan tests => 16,
	need_module("DBI"),
	need_module("DBD::Mock"),
	need_module("Sub::Override");
}

my $m; BEGIN { use_ok($m = "Verby::Action::Mysql::CreateDB") }

my $dbh = DBI->connect("dbi:Mock:", {});

$INC{"DBI/db.pm"} = 1;
my $dbh_dsns = Test::MockObject::Extends->new($dbh);

$dbh_dsns->set_always( data_sources => qw/dbi:Mock:foo/ );
$dbh_dsns->mock(do => sub {
	my $self = shift;

	my ($sql, undef, $db_name) = @_;
	
	if ($sql =~ /create database/i){
		# if we are creating a DB, add it to the data sources, sort of.
		$self->set_list( data_sources => $self->data_sources, "dbi:Mock:$db_name" );
		# now our job is done, we can unmock
		$self->unmock("do");
	}
	$self->do(@_);
});

my $c = Hash::AsObject->new;
$c->dbh($dbh_dsns);
$c->db_name("foo");
$c->logger(my $logger = Test::MockObject->new);

$logger->set_true("info");
$logger->mock(logdie => sub { shift; die "@_" });

isa_ok(my $a = $m->new, $m);

ok($a->verify($c), "db foo exists");
lives_ok { $a->confirm($c) } "confirm lives";

$dbh_dsns->called_ok("data_sources");

$c->db_name("bar");

ok(!$a->verify($c), "db bar does not exist");
dies_ok { $a->confirm($c) } "confirm dies";

ok(!$logger->called("info"), "no log message yet");

my $history = $dbh->{mock_all_history};
is(@$history, 0, "no history yet");


lives_ok { $a->do($c) } "create lives";

is(@$history, 1, "one statment in history");
my $sth = $history->[0];
like($sth->statement, qr/^\s*create\s+database\s+\?\s*;?/i, "create db sql");
is($sth->bound_params->[0], "bar", "bound param was 'bar'");

ok($a->verify($c), "db bar now exists");
lives_ok { $a->confirm($c) } "confirm lives";

$logger->called_ok("info");

