#---------------------------------------------------------------------
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Omap.t'

use strict;
use warnings;

use Test::More 'no_plan';

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=0;

BEGIN { use_ok('Data::Omap') };

#---------------------------------------------------------------------
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

SIMPLE: {

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

}

ORDERING: {

my( $omap );

$omap = Data::Omap->new();
Data::Omap->order( 'sa' );  # string ascending

$omap->set( z => 26 );
$omap->set( y => 25 );
$omap->set( x => 24 );
is( Dumper($omap), "bless( [{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "set(), ordering 'sa'" );

$omap->add( a => 1 );
is( Dumper($omap), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "add(), ordering 'sa'" );

is( ref( Data::Omap->order() ), 'CODE',
    "order() returns code ref when ordering is on" );

is( Data::Omap->order( '' ), '',
    "order('') turns ordering off" );

$omap->add( b => 2 );
is( Dumper($omap), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26},{'b' => 2}], 'Data::Omap' )",
    "add(), no ordering" );

$omap->clear();
Data::Omap->order( 'sa' );  # string ascending turned on again

$omap->set( 100 => 'hundred' );
$omap->set( 10  => 'ten' );
$omap->set( 2   => 'two' );
is( Dumper($omap), "bless( [{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Omap' )",
    "set(), ordering 'sa'" );

$omap->add( 1 => 'one' );
is( Dumper($omap), "bless( [{'1' => 'one'},{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Omap' )",
    "add(), ordering 'sa'" );

$omap->clear();
Data::Omap->order( 'na' );  # number ascending

$omap->set( 100 => 'hundred' );
$omap->set( 10  => 'ten' );
$omap->set( 2   => 'two' );
is( Dumper($omap), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Omap' )",
    "set(), ordering 'na'" );

$omap->add( 1 => 'one' );
is( Dumper($omap), "bless( [{'1' => 'one'},{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Omap' )",
    "add(), ordering 'na'" );

$omap->clear();
Data::Omap->order( 'sd' );  # string descending

$omap->set( x => 24 );
$omap->set( y => 25 );
$omap->set( z => 26 );
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24}], 'Data::Omap' )",
    "set(), ordering 'sd'" );

$omap->add( a => 1 );
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'a' => 1}], 'Data::Omap' )",
    "add(), ordering 'sd'" );

$omap->clear();

$omap->set( 2   => 'two' );  # order still 'sd'
$omap->set( 10  => 'ten' );
$omap->set( 100 => 'hundred' );
is( Dumper($omap), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'}], 'Data::Omap' )",
    "set(), ordering 'sd'" );

$omap->add( 1 => 'one' );
is( Dumper($omap), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'},{'1' => 'one'}], 'Data::Omap' )",
    "add(), ordering 'sd'" );

$omap->clear();
Data::Omap->order( 'nd' );  # number descending

$omap->set( 2   => 'two' );
$omap->set( 10  => 'ten' );
$omap->set( 100 => 'hundred' );
is( Dumper($omap), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Omap' )",
    "set(), ordering 'nd'" );

$omap->add( 1 => 'one' );
is( Dumper($omap), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'},{'1' => 'one'}], 'Data::Omap' )",
    "add(), ordering 'nd'" );

$omap->clear();
Data::Omap->order( 'sna' );  # string/number ascending
$omap->set( z => 26 );
$omap->set( y => 25 );
$omap->add( x => 24 );  # set and add are the same for new key/value members
$omap->set( 100 => 'hundred' );
$omap->set( 10  => 'ten' );
$omap->add( 2   => 'two' );
is( Dumper($omap), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "set()/add(), ordering 'sna'" );

$omap->clear();
Data::Omap->order( 'snd' );  # string/number descending
$omap->add( x => 24 );  # set and add are the same for new key/value members
$omap->set( y => 25 );
$omap->set( z => 26 );
$omap->add( 2   => 'two' );
$omap->set( 10  => 'ten' );
$omap->set( 100 => 'hundred' );
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Omap' )",
    "set()/add(), ordering 'snd'" );

$omap->clear();
Data::Omap->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # custom ordering
$omap->set( 550 => "note" );
$omap->set( 500 => "note" );
$omap->set( 510 => "note" );
$omap->set( 650 => "subj" );
$omap->set( 600 => "subj" );
$omap->set( 610 => "subj" );
$omap->set( 245 => "title" );
$omap->set( 100 => "author" );
is( Dumper($omap), "bless( [{'100' => 'author'},{'245' => 'title'},{'550' => 'note'},{'500' => 'note'},{'510' => 'note'},{'650' => 'subj'},{'600' => 'subj'},{'610' => 'subj'}], 'Data::Omap' )",
    "set(), custom ordering" );

}

TIED: {

my( $omap, %omap, @keys, @values, $bool, $key, $value, @a );

Data::Omap->order( '' );  # ordering is class-level, turn off for now

$omap = tie %omap, 'Data::Omap';

is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "empty tied object" );

# empty %omap

@keys = keys %omap;  # via FIRSTKEY/NEXTKEY
is( "@keys", "",
    "keys %hash on empty object" );

@values = values %omap;  # via FIRSTKEY/NEXTKEY
is( "@values", "",
    "values %hash on empty object" );

$bool = %omap;   # SCALAR
is( $bool, undef,
    "scalar %hash on empty object" );

$bool = exists $omap{ a };  # EXISTS
is( $bool, '',
    "exists hash{key} on empty object" );  # false (Why '' and not undef? Don't know.)

$value = $omap{ a };  # FETCH
is( $value, undef,
    "hash{key} (FETCH) on empty object" );

delete $omap{ a };  # DELETE
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "delete hash{key} on empty object" );

%omap = ();  # CLEAR
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "%hash = () to clear empty object" );

# non-empty %omap

$omap{ z } = 26;  # STORE
$omap{ y } = 25;
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25}], 'Data::Omap' )",
    "hash{key}=value" );

$bool = exists $omap{ z };
is( $bool, 1,
    "exists hash{key}" );

$value = $omap{ z };
is( $value, 26,
    "value=hash{key}" );

@values = @omap{ 'y', 'z' };
is( "@values", "25 26",
    "values=\@hash{key,key} (get slice)" );

@omap{ 'y', 'z' } = ( "Why", "Zee" );
is( Dumper($omap), "bless( [{'z' => 'Zee'},{'y' => 'Why'}], 'Data::Omap' )",
    "\@hash{key,key}=values (set slice)" );

delete $omap{ z };
is( Dumper($omap), "bless( [{'y' => 'Why'}], 'Data::Omap' )",
    "delete hash{key}" );

@omap{ 'a', 'b', 'c' } = ( 1, 2, 3 );
@keys = keys %omap;
is( "@keys", "y a b c",
    "keys %hash" );

@values = values %omap;
is( "@values", "Why 1 2 3",
    "values %hash" );

while( ( $key, $value ) = each %omap ) {
    push @a, "$key $value";
}
is( "@a", "y Why a 1 b 2 c 3",
    "each %hash" ); 

$bool = %omap;
is( $bool, 4,
    "scalar %hash" );

%omap = ();  # CLEAR
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "%hash = () to clear hash" );

my $warning;
local $SIG{ __WARN__ } = sub{ ($warning) = @_ };
untie %omap;
like( $warning, qr/untie attempted while 1 inner references still exist/,
    "expected untie warning (object still in scope)" );
is( Dumper($omap), "bless( [], 'Data::Omap' )",
    "(empty) object is still visible" );

}

TIED_ORDERING: {

my( $omap, %omap, @keys, @values, $bool, $key, $value, @a );

$omap = tie %omap, 'Data::Omap';

Data::Omap->order( 'sa' );  # string ascending

$omap{ z } = 26;
$omap{ y } = 25;
$omap{ x } = 24;
is( Dumper($omap), "bless( [{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sa'" );

$omap{ a } = 1;
is( Dumper($omap), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sa'" );

Data::Omap->order( '' );  # turn ordering off

$omap{ b } = 2;
is( Dumper($omap), "bless( [{'a' => 1},{'x' => 24},{'y' => 25},{'z' => 26},{'b' => 2}], 'Data::Omap' )",
    "hash{key}=value, no ordering" );

%omap = ();
Data::Omap->order( 'sa' );  # string ascending turned on again

$omap{ 100 } = 'hundred';
$omap{ 10  } = 'ten';
$omap{ 2   } = 'two';
is( Dumper($omap), "bless( [{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sa'" );

$omap{ 1 } = 'one';
is( Dumper($omap), "bless( [{'1' => 'one'},{'10' => 'ten'},{'100' => 'hundred'},{'2' => 'two'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sa'" );

%omap = ();
Data::Omap->order( 'na' );  # number ascending

$omap{ 100 } = 'hundred';
$omap{ 10  } = 'ten';
$omap{ 2   } = 'two';
is( Dumper($omap), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'na'" );

$omap{ 1 } = 'one';
is( Dumper($omap), "bless( [{'1' => 'one'},{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'na'" );

%omap = ();
Data::Omap->order( 'sd' );  # string descending

$omap{ x } = 24;
$omap{ y } = 25;
$omap{ z } = 26;
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sd'" );

$omap{ a } = 1;
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'a' => 1}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sd'" );

%omap = ();

$omap{ 2   } = 'two';  # order still 'sd'
$omap{ 10  } = 'ten';
$omap{ 100 } = 'hundred';
is( Dumper($omap), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sd'" );

$omap{ 1 } = 'one';
is( Dumper($omap), "bless( [{'2' => 'two'},{'100' => 'hundred'},{'10' => 'ten'},{'1' => 'one'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sd'" );

%omap = ();
Data::Omap->order( 'nd' );  # number descending

$omap{ 2   } = 'two';
$omap{ 10  } = 'ten';
$omap{ 100 } = 'hundred';
is( Dumper($omap), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'nd'" );

$omap{ 1 } = 'one';
is( Dumper($omap), "bless( [{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'},{'1' => 'one'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'nd'" );

%omap = ();
Data::Omap->order( 'sna' );  # string/number ascending
$omap{ z } = 26;
$omap{ y } = 25;
$omap{ x } = 24;  # set and add are the same for new key/value members
$omap{ 100 } = 'hundred';
$omap{ 10  } = 'ten';
$omap{ 2   } = 'two';
is( Dumper($omap), "bless( [{'2' => 'two'},{'10' => 'ten'},{'100' => 'hundred'},{'x' => 24},{'y' => 25},{'z' => 26}], 'Data::Omap' )",
    "hash{key}=value, ordering 'sna'" );

%omap = ();
Data::Omap->order( 'snd' );  # string/number descending
$omap{ x } = 24;  # set and add are the same for new key/value members
$omap{ y } = 25;
$omap{ z } = 26;
$omap{ 2   } = 'two';
$omap{ 10  } = 'ten';
$omap{ 100 } = 'hundred';
is( Dumper($omap), "bless( [{'z' => 26},{'y' => 25},{'x' => 24},{'100' => 'hundred'},{'10' => 'ten'},{'2' => 'two'}], 'Data::Omap' )",
    "hash{key}=value, ordering 'snd'" );

%omap = ();
Data::Omap->order( sub{ int($_[0]/100) < int($_[1]/100) } );  # custom ordering
$omap{ 550 } = "note";
$omap{ 500 } = "note";
$omap{ 510 } = "note";
$omap{ 650 } = "subj";
$omap{ 600 } = "subj";
$omap{ 610 } = "subj";
$omap{ 245 } = "title";
$omap{ 100 } = "author";
is( Dumper($omap), "bless( [{'100' => 'author'},{'245' => 'title'},{'550' => 'note'},{'500' => 'note'},{'510' => 'note'},{'650' => 'subj'},{'600' => 'subj'},{'610' => 'subj'}], 'Data::Omap' )",
    "hash{key}=value, custom ordering" );

}
