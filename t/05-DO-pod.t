use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Omap') };

SYNOPSIS_simple: {
 
     # Simple OO style
 
     my $omap = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );
 
     $omap->set( a => 0 );

is( Dumper($omap), "bless( [{'a' => 0},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "set( a => 0 )" );

     $omap->add( b2 => 2.5, 2 );  # insert at position 2 (between b and c)
 
is( Dumper($omap), "bless( [{'a' => 0},{'b' => 2},{'b2' => '2.5'},{'c' => 3}], 'Data::Omap' )",
    "add( b2 => 2.5, 2 )" );

     my $value  = $omap->get_values( 'c' );    # 3

is( $value, 3, "get_values( 'c' )" );

     my @keys   = $omap->get_keys();           # (a, b, b2, c)

is( "@keys", "a b b2 c", "get_keys()" );

     my @values = $omap->get_values();         # (0, 2, 2.5, 3)

is( "@values", "0 2 2.5 3", "get_values()" );

     my @subset = $omap->get_values(qw(c b));  # (2, 3) (values are data-ordered)

is( "@subset", "2 3", "get_values(qw(c b ))" );

}

SYNOPSIS_tied: {
 
     # Tied style
 
     my %omap;
     # recommend saving an object reference, too.
     my $omap = tie %omap, 'Data::Omap', [{a=>1},{b=>2},{c=>3}];
 
is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "tie %omap" );
 
     $omap{ a } = 0;

is( Dumper($omap), "bless( [{'a' => 0},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "$omap{ a } = 0" );
 
     $omap->add( b2 => 2.5, 2 );  # there's no tied hash equivalent
 
is( Dumper($omap), "bless( [{'a' => 0},{'b' => 2},{'b2' => '2.5'},{'c' => 3}], 'Data::Omap' )",
    "add( b2 => 2.5, 2 )" );

     my $value  = $omap{ c };

is( $value, 3, "\$omap{ c }" );

     my @keys   = keys %omap;      # $omap->get_keys() is faster 

is( "@keys", "a b b2 c", "keys %omap" );

     my @values = values %omap;    # $omap->get_values() is faster

is( "@values", "0 2 2.5 3", "values %omap" );

     my @slice  = @omap{qw(c b)};  # (3, 2) (slice values are parameter-ordered)

is( "@slice", "3 2", "\@omap{qw(c b)}" );
 
     # There are more methods/options, see below.
}


CLASS_new: {

     my $omap = Data::Omap->new( [ { a => 1 }, { b => 2 }, { c => 3 } ] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

}

CLASS_order: {

     Data::Omap->order();         # leaves ordering as is

is( Data::Omap->order(), undef, "order()" );

     Data::Omap->order( '' );     # turn ordering OFF (the default)

is( Data::Omap->order(), '', "order( '' )" );

     Data::Omap->order( 'na' );   # numeric ascending

is( ref(Data::Omap->order()), 'CODE', "order( 'na' )" );

     Data::Omap->order( 'nd' );   # numeric ascending

is( ref(Data::Omap->order()), 'CODE', "order( 'nd' )" );

     Data::Omap->order( 'sa' );   # string  ascending

is( ref(Data::Omap->order()), 'CODE', "order( 'sa' )" );

     Data::Omap->order( 'sd' );   # string  descending

is( ref(Data::Omap->order()), 'CODE', "order( 'sd' )" );

     Data::Omap->order( 'sna' );  # string/numeric ascending

is( ref(Data::Omap->order()), 'CODE', "order( 'sna' )" );

     Data::Omap->order( 'snd' );  # string/numeric descending

is( ref(Data::Omap->order()), 'CODE', "order( 'snd' )" );

     Data::Omap->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # code

is( ref(Data::Omap->order()), 'CODE', "custom order()" );

}

OBJECT_set: {

     my $omap = Data::Omap->new( [{a=>1},{b=>2}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2}], 'Data::Omap' )",
    "new()" );

     $omap->set( c => 3, 0 );  # omap is now [{c=>3},{b=>2}]

is( Dumper($omap), "bless( [{'c' => 3},{'b' => 2}], 'Data::Omap' )",
    "set()" );

}

OBJECT_get_values: {

     my $omap = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

     my @values  = $omap->get_values();  # (1, 2, 3)

is( "@values", "1 2 3",
    "get_values(), list" );

     my $howmany = $omap->get_values();  # 3

is( $howmany, 3,
    "get_values(), scalar" );

     @values   = $omap->get_values( 'b' );  # (2)

is( "@values", 2,
    "get_values( 'b' ), list" );

     my $value = $omap->get_values( 'b' );  # 2

is( $value, 2,
    "get_values( 'b' ), scalar" );

     @values  = $omap->get_values( 'c', 'b', 'A' );  # (2, 3)

is( "@values", "2 3",
    "get_values( 'c', 'b', 'A' ), list" );

     $howmany = $omap->get_values( 'c', 'b', 'A' );  # 2

is( $howmany, 2,
    "get_values( 'c', 'b', 'A' ), scalar" );

}

OBJECT_add: {

     my $omap = Data::Omap->new( [{a=>1},{b=>2}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2}], 'Data::Omap' )",
    "new()" );

     $omap->add( c => 3, 1 );  # omap is now [{a=>1},{c=>3},{b=>2}]

is( Dumper($omap), "bless( [{'a' => 1},{'c' => 3},{'b' => 2}], 'Data::Omap' )",
    "add( c => 3, 1 )" );

}

OBJECT_get_pos: {

     my $omap    = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

     my @pos = $omap->get_pos( 'b' );  # (1)

is( "@pos", 1,
    "get_pos( 'b' ), list" );

     my $pos = $omap->get_pos( 'b' );  # 1

is( $pos, 1,
    "get_pos( 'b' ), scalar" );

     @pos        = $omap->get_pos( 'c', 'b' );       # @pos is (2, 1)

is( "@pos", "2 1",
    "get_pos( 'c', 'b' ), list" );

     my $howmany = $omap->get_pos( 'A', 'b', 'c' );  # $howmany is 2

is( $howmany, 2,
    "get_pos( 'A', 'b', 'c' ), scalar" );

}

OBJECT_get_keys: {

     my $omap    = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

     my @keys    = $omap->get_keys();  # @keys is (a, b, c)

is( "@keys", "a b c",
    "get_keys(), list" );

     my $howmany = $omap->get_keys();  # $howmany is 3

is( $howmany, 3,
    "get_keys(), scalar" );

     @keys    = $omap->get_keys( 'c', 'b', 'A' );  # @keys is (b, c)

is( "@keys", "b c",
    "get_keys( 'c', 'b', 'A' ), list" );

     $howmany = $omap->get_keys( 'c', 'b', 'A' );  # $howmany is 2

is( $howmany, 2,
    "get_keys( 'c', 'b', 'A' ), scalar" );

}

OBJECT_get_array: {

     my $omap    = Data::Omap->new( [{a=>1},{b=>2},{c=>3}] );

is( Dumper($omap), "bless( [{'a' => 1},{'b' => 2},{'c' => 3}], 'Data::Omap' )",
    "new()" );

     my @array   = $omap->get_array();  # @array is ({a=>1}, {b=>2}, {c=>3})

is( Dumper(\@array), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "get_array(), list" );

     my $aref    = $omap->get_array();  # $aref  is [{a=>1}, {b=>2}, {c=>3}]

is( Dumper($aref), "[{'a' => 1},{'b' => 2},{'c' => 3}]",
    "get_array(), scalar" );

     @array = $omap->get_array( 'c', 'b', 'A' );  # @array is ({b->2}, {c=>3})

is( Dumper(\@array), "[{'b' => 2},{'c' => 3}]",
    "get_array( 'c', 'b', 'A' ), list" );

     $aref  = $omap->get_array( 'c', 'b', 'A' );  # @aref  is [{b->2}, {c=>3}]

is( Dumper($aref), "[{'b' => 2},{'c' => 3}]",
    "get_array( 'c', 'b', 'A' ), scalar" );

}

