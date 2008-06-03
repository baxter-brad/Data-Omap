use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Omap') };

my( $omap, @values, @keys, @pos, $clone );

$omap = Data::Omap->new( [ {c=>3}, {a=>1}, {b=>2}, ] );

@values = $omap->get();
is( "@values", "3 1 2",
    "get() all values, like 'values %hash'" );

@values = $omap->get( qw( a b c ) );
is( "@values", "3 1 2",
    "get() selected values, like '\@hash{'c','a','b'}', i.e., data-ordered" );

@keys = $omap->get_keys();
is( "@keys", "c a b",
    "get_keys(), like 'keys %hash'" );

@keys = $omap->get_keys( qw( a b c ) );
is( "@keys", "c a b",
    "get_keys() for selected keys, data-ordered" );

@pos = $omap->get_pos( qw( a b c ) ); # 1 is pos of 'a', 2 of 'b', 0 of 'c'
is( "@pos", "1 2 0",
    "get_pos() for selected keys, parameter-ordered" );

$clone = $omap->clone();
is( Dumper($clone), "[{'c' => 3},{'a' => 1},{'b' => 2}]",
    "clone() entire self" );

$clone = $omap->clone( qw( b c ) );
is( Dumper($clone), "[{'c' => 3},{'b' => 2}]",
    "clone() selected keys" );

$omap->set( a=>0 ); @values = $omap->get( qw( a b c ) );
is( "@values", "3 0 2",
    "set() a value" );

# at pos 1, overwrite 'a'
$omap->set( A=>1,1 ); @values = $omap->get( qw( A b c ) );
is( "@values", "3 1 2",
    "set() a value at a position" );

$omap->add( d=>4 ); @values = $omap->get( qw( A b c d ) );
is( "@values", "3 1 2 4",
    "add() a value" );

# add at pos 2, between 'A' and 'b'
$omap->add( a=>0,2 ); @values = $omap->get( qw( A a b c d ) );
is( "@values", "3 1 0 2 4",
    "add() a value at a position" );

# firstkey/nextkey to support TIEHASH
is( $omap->firstkey(), 'c',
    "firstkey()" );  
is( $omap->nextkey('c'), 'A',
    "nextkey()" );
is( $omap->nextkey('b'), 'd',
    "nextkey()" );

is( $omap->exists('a'), 1,
    "exists() true" );
is( $omap->exists('B'), undef,
    "exists() false" );

$omap->delete('A');
is( Dumper($omap), "bless( [{'c' => 3},{'a' => 0},{'b' => 2},{'d' => 4}], 'Data::Omap' )",
    "delete()" );

$omap->clear();
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "clear()" );

