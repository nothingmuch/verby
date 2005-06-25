#!/usr/bin/perl

use Log::Log4perl;
use Verby::Config::Source::Prompt;


my $l4pconf = <<L4P;
	log4perl.rootLogger 			= INFO, term

	log4perl.appender.term			= Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.term.layout	= Log::Log4perl::Layout::SimpleLayout::Multiline
L4P
Log::Log4perl::init(\$l4pconf);

my $c = Verby::Config::Source::Prompt->new(
	{
		foo => "Please tell about møøse: "
	},
	#{asap => 1},
);

print "If `asap` is on this should be printed after the question\n";

print "foo: " . $c->foo .  "\n";
print "this should be an error: " . $c->bar . "\n";
