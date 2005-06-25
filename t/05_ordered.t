#!/usr/bin/perl

# Ordered dependency trees

use strict;
use warnings;

use Test::More 'no_plan';

{
	package SomeObj;
	use Scalar::Util qw/refaddr/;

	my $id = 'A';
	my %id;
	
	sub id { $id{refaddr $_[0]} }
	sub new {
		my $pkg = shift;
		my $self = bless [ @_ ], $pkg;
		$id{refaddr $self} = $id++;
		$self;
	}
	sub depends {
		@{ $_[0] }
	}
}

use Set::Object;

my $objs = Set::Object->new(my ($a,$b,$c,$d,$e,$f) = map { SomeObj->new() } qw/A B C D E F/);
@$b = ($c);
@$d = ($e, $f);



BEGIN { use_ok($m = "Algorithm::Dependency::Ordered") };
# Load the source files
my $basic = File::Spec->catfile( $TESTDATA, 'basics.txt' );
my $BSource = Algorithm::Dependency::Source::File->new( $basic );
ok( $BSource, "Basic source created" );
ok( eval {$BSource->load;}, "Basic source loads" );
my $complex = File::Spec->catfile( $TESTDATA, 'complex.txt' );
my $CSource = Algorithm::Dependency::Source::File->new( $complex );
ok( $CSource, "Complex source created" );
ok( eval {$CSource->load;}, "Complex source loads" );





# Test the creation of a basic ordered dependency tree
my $BDep = Algorithm::Dependency::Ordered->new( source => $BSource, selected => ['B'] );
ok( $BDep, "Algorithm::Dependency::Ordered->new returns true" );
ok( ref $BDep, "Algorithm::Dependency::Ordered->new returns reference" );
ok( isa( $BDep, 'Algorithm::Dependency::Ordered'), "Algorithm::Dependency::Ordered->new returns an Algorithm::Dependency::Ordered" );
ok( isa( $BDep, 'Algorithm::Dependency'), "Algorithm::Dependency::Ordered->new returns an Algorithm::Dependency" );
ok( $BDep->source, "Dependency->source returns true" );
ok( $BDep->source eq $BSource, "Dependency->source returns the original source" );
ok( $BDep->item('A'), "Dependency->item returns true" );
ok( $BDep->item('A') eq $BSource->item('A'), "Dependency->item returns the same as Basic->item" );
my @tmp;
ok( scalar( @tmp = $BDep->selected_list ) == 1, "Dependency->selected_list returns empty list" );
ok( $tmp[0] eq 'B', "Dependency->selected_list returns as expected" );
ok( ! $BDep->selected('Foo'), "Dependency->selected returns false on bad input" );
ok( ! $BDep->selected('A'), "Dependency->selected returns false when not selected" );
ok( $BDep->selected('B'), "Dependency->selected returns true when selected" );
ok( ! defined $BDep->depends('Foo'), "Dependency->depends fails correctly on bad input" );





# Check the results of it's depends and schedule methods
$BDep = Algorithm::Dependency::Ordered->new( source => $BSource );
foreach my $data ( [
	['A'],	[],		['A'] 		], [
	['B'],	['C'],		[qw{C B}] 	], [
	['C'],	[], 		['C']		], [
	['D'],	[qw{E F}],	[qw{E F D}]	], [
	['E'],	[],		['E']		], [
	['F'],	[],		['F']		]
) {
	my $args = join( ', ', map { "'$_'" } @{ $data->[0] } );
	my $rv = $BDep->depends( @{ $data->[0] } );
	ok( $rv, "Dependency->depends($args) returns something" );
	is_deeply( $rv, $data->[1], "Dependency->depends($args) returns expected values" );
	$rv = $BDep->schedule( @{ $data->[0] } );
	ok( $rv, "Dependency->schedule($args) returns something" );
	is_deeply( $rv, $data->[2], "Dependency->schedule($args) returns expected values" );
}





# Now do the ordered dependency on the complex data set
my $CDep = Algorithm::Dependency::Ordered->new( source => $CSource );
ok( $CDep, "Algorithm::Dependency::Ordered->new returns true" );
ok( ref $CDep, "Algorithm::Dependency::Ordered->new returns reference" );
ok( isa( $CDep, 'Algorithm::Dependency::Ordered'), "Algorithm::Dependency::Ordered->new returns correctly" );

# Test each of the dependencies
foreach my $data ( [
	['A'],		[],				['A'] 				], [
	['B'],		['C'],				[qw{C B}] 			], [
	['C'],		[], 				['C']				], [
	['D'],		[qw{E F}],			[qw{F E D}]			], [
	['E'],		['F'],				[qw{F E}]			], [
	['F'],		[],				['F']				], [
	['G'],		[qw{H I J}],			[qw{J I H G}]			], [
	['H'],		[qw{I J}],			[qw{J I H}]			], [
	['I'],		['J'],				[qw{J I}]			], [
	['J'],		[],				['J']				], [
	['K'],		[qw{L M}],			[qw{M L K}]			], [
	['L'],		['M'],				[qw{M L}]			], [
	['M'],		[],				['M']				], [
	['N'],		[],				['N']				], [
	['O'],		['N'],				[qw{N O}]			], [
	['P'],		['N'],				[qw{N P}]			], [
	['Q'],		[qw{N O}],			[qw{N O Q}]			], [
	['R'],		[qw{N P}],			[qw{N P R}]			], [
	['S'],		[qw{N O P Q R}],		[qw{N O P Q R S}]		], [
	['T'],		[qw{A D E F K L M N P R}],	[qw{A F M N P R E L D K T}]	]
) {
	my $args = join( ', ', map { "'$_'" } @{ $data->[0] } );
	my $rv = $CDep->depends( @{ $data->[0] } );
	ok( $rv, "Dependency->depends($args) returns something" );
	is_deeply( $rv, $data->[1], "Dependency->depends($args) returns expected values" );
	$rv = $CDep->schedule( @{ $data->[0] } );
	ok( $rv, "Dependency->schedule($args) returns something" );
	is_deeply( $rv, $data->[2], "Dependency->schedule($args) returns expected values" );
}





# Now do the ordered dependency on the complex data set
$CDep = Algorithm::Dependency::Ordered->new( source => $CSource, selected => [qw{F H J N R P}] );
ok( $CDep, "Algorithm::Dependency::Ordered->new returns true" );
ok( ref $CDep, "Algorithm::Dependency::Ordered->new returns reference" );
ok( isa( $CDep, 'Algorithm::Dependency::Ordered'), "Algorithm::Dependency::Ordered->new returns correctly" );

# Test each of the dependencies
foreach my $data ( [
	['A'],		[],			['A'] 			], [
	['B'],		['C'],			[qw{C B}] 		], [
	['C'],		[], 			['C']			], [
	['D'],		['E'],			[qw{E D}]		], [
	['E'],		[],			['E']			], [
	['F'],		[],			[]			], [
	['G'],		['I'],			[qw{G I}]		], [
	['H'],		['I'],			['I']			], [
	['I'],		[],			['I']			], [
	['J'],		[],			[]			], [
	['K'],		[qw{L M}],		[qw{M L K}]		], [
	['L'],		['M'],			[qw{M L}]		], [
	['M'],		[],			['M']			], [
	['N'],		[],			[]			], [
	['O'],		[],			['O']			], [
	['P'],		[],			[]			], [
	['Q'],		['O'],			[qw{O Q}]		], [
	['R'],		[],			[]			], [
	['S'],		[qw{O Q}],		[qw{O Q S}]		], [
	['T'],		[qw{A D E K L M}], 	[qw{A E M D L K T}]	]
) {
	my $args = join( ', ', map { "'$_'" } @{ $data->[0] } );
	my $rv = $CDep->depends( @{ $data->[0] } );
	ok( $rv, "Dependency->depends($args) returns something" );
	is_deeply( $rv, $data->[1], "Dependency->depends($args) returns expected values" );
	$rv = $CDep->schedule( @{ $data->[0] } );
	ok( $rv, "Dependency->schedule($args) returns something" );
	is_deeply( $rv, $data->[2], "Dependency->schedule($args) returns expected values" );
}

1;
