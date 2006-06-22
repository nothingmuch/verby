#!/usr/bin/perl

# usage:
# perl -Ilib  verby_par.pl -o module_builder examples/module_builder.pl 

use strict;
use warnings;

my $script = pop @ARGV;

open my $fh, "<", $script or die "can't open($script): $!";

my @extra;
for ( <$fh> ) { push @extra, $1 if /step\s*[\s\(]\s*["']([\w:]+)["']/; last if /__(END|DATA)__/ }

my %seen;
@extra = grep { !$seen{$_}++ } @extra;

close $fh;

warn join("\n", "Bundling extra modules (from step 'Foo' syntax):", map { "- $_" } @extra) . "\n";

$ENV{PERL5LIB} = join(":", @INC);
exec(qw/pp -P -x/, (map { ("-M", $_) } @extra), @ARGV, $script );


