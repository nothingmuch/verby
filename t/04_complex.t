#!/usr/bin/perl

# More complex dependency trees

use strict;
use warnings;

use Test::More 'no_plan';

my $m;
BEGIN { use_ok($m = "Algorithm::Dependency") }


# Try it's unordere dependency with nothing selected
my $Dep = Algorithm::Dependency->new( source => $Source );
ok( $Dep, "Algorithm::Dependency->new returns true" );
ok( ref $Dep, "Algorithm::Dependency->new returns reference" );
ok( isa( $Dep, 'Algorithm::Dependency'), "Algorithm::Dependency->new returns correctly" );

# Test each of the dependencies
foreach my $data ( [
	['A'],		[],				['A'] 				], [
	['B'],		['C'],				[qw{B C}] 			], [
	['C'],		[], 				['C']				], [
	['D'],		[qw{E F}],			[qw{D E F}]			], [
	['E'],		['F'],				[qw{E F}]			], [
	['F'],		[],				['F']				], [
	['G'],		[qw{H I J}],			[qw{G H I J}]			], [
	['H'],		[qw{I J}],			[qw{H I J}]			], [
	['I'],		['J'],				[qw{I J}]			], [
	['J'],		[],				['J']				], [
	['K'],		[qw{L M}],			[qw{K L M}]			], [
	['L'],		['M'],				[qw{L M}]			], [
	['M'],		[],				['M']				], [
	['N'],		[],				['N']				], [
	['O'],		['N'],				[qw{N O}]			], [
	['P'],		['N'],				[qw{N P}]			], [
	['Q'],		[qw{N O}],			[qw{N O Q}]			], [
	['R'],		[qw{N P}],			[qw{N P R}]			], [
	['S'],		[qw{N O P Q R}],		[qw{N O P Q R S}]		], [
	['T'],		[qw{A D E F K L M N P R}],	[qw{A D E F K L M N P R T}]	]
) {
	my $args = join( ', ', map { "'$_'" } @{ $data->[0] } );
	my $rv = $Dep->depends( @{ $data->[0] } );
	ok( $rv, "Dependency->depends($args) returns something" );
	is_deeply( $rv, $data->[1], "Dependency->depends($args) returns expected values" );
	$rv = $Dep->schedule( @{ $data->[0] } );
	ok( $rv, "Dependency->schedule($args) returns something" );
	is_deeply( $rv, $data->[2], "Dependency->schedule($args) returns expected values" );
}





# Try an unordered dependency with half a dozen random things selected
$Dep = Algorithm::Dependency->new( source => $Source, selected => [qw{F H J N R P}] );
ok( $Dep, "Algorithm::Dependency->new returns true" );
ok( ref $Dep, "Algorithm::Dependency->new returns reference" );
ok( isa( $Dep, 'Algorithm::Dependency'), "Algorithm::Dependency->new returns correctly" );

# Test each of the dependencies
foreach my $data ( [
	['A'],		[],			['A'] 			], [
	['B'],		['C'],			[qw{B C}] 		], [
	['C'],		[], 			['C']			], [
	['D'],		['E'],			[qw{D E}]		], [
	['E'],		[],			['E']			], [
	['F'],		[],			[]			], [
	['G'],		['I'],			[qw{G I}]		], [
	['H'],		['I'],			['I']			], [
	['I'],		[],			['I']			], [
	['J'],		[],			[]			], [
	['K'],		[qw{L M}],		[qw{K L M}]		], [
	['L'],		['M'],			[qw{L M}]		], [
	['M'],		[],			['M']			], [
	['N'],		[],			[]			], [
	['O'],		[],			['O']			], [
	['P'],		[],			[]			], [
	['Q'],		['O'],			[qw{O Q}]		], [
	['R'],		[],			[]			], [
	['S'],		[qw{O Q}],		[qw{O Q S}]		], [
	['T'],		[qw{A D E K L M}], 	[qw{A D E K L M T}]	]
) {
	my $args = join( ', ', map { "'$_'" } @{ $data->[0] } );
	my $rv = $Dep->depends( @{ $data->[0] } );
	ok( $rv, "Dependency->depends($args) returns something" );
	is_deeply( $rv, $data->[1], "Dependency->depends($args) returns expected values" );
	$rv = $Dep->schedule( @{ $data->[0] } );
	ok( $rv, "Dependency->schedule($args) returns something" );
	is_deeply( $rv, $data->[2], "Dependency->schedule($args) returns expected values" );
}

# Do a quick check of the missing_dependencies methods
is( $Source->missing_dependencies, 0, "->missing_dependencies returns as expected" );

1;
