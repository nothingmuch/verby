#!/usr/bin/perl

use File::Temp qw/tempdir/;

use Dispatcher;
use Step::Closure qw/step/;
use Config::Data;
use File::Basename;

my $l4pconf = <<L4P;
	log4perl.rootLogger 			= INFO, term

	log4perl.appender.term			= Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.term.layout	= Log::Log4perl::Layout::SimpleLayout::Multiline
L4P
Log::Log4perl::init(\$l4pconf);

my $cfg = Config::Data->new;
%{ $cfg->data } = (
	project_root => my $out_dir = tempdir(CLEANUP => 1),
	company_name => "Beer rocks!",
	perl_module_namespace => "Acme::Møøse",
	project_url => "http://goatse.cx",
);

my $tmpl_dir = "EERS_demo/templates";

my %by_dir = (
	conf => [qw/httpd.conf startup.pl startup.xml/],
	"perl/foo" => [qw/main.pm/],
);

my $d = Dispatcher->new;
$d->config_hub($cfg);

foreach my $dir (keys %by_dir){
	foreach my $file (@{ $by_dir{$dir} }){
		my $in = "$tmpl_dir/$file";
		my $out = "$out_dir/$dir/$file";
		my $t = step "Action::Template" => sub {
			my $c = $_[1];
			$c->template($in);
			$c->output($out);
	   	};
		my $path = dirname($out);
		$t->depends(step "Action::MkPath" => sub { $_[1]->path($path) });
		$d->add_step($t);
	}
}

$d->do_all;

