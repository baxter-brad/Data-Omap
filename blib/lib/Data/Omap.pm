#---------------------------------------------------------------------
  package Data::Omap;
#---------------------------------------------------------------------

=head1 NAME

Data::Omap

=head1 SYNOPSIS

use Data::Omap;

=cut

use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util qw( reftype looks_like_number );

my $order;  # package global, see order() accessor

#---------------------------------------------------------------------
# class methods
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Data::Omap->new( [{init=>'values'},{if=>'desired'}] );
# returns object reference

sub new {
    my( $class, $aref ) = @_;
    return bless [], $class unless $aref;

    die "\$aref must be aref" unless reftype( $aref ) eq 'ARRAY';
    bless $aref, $class;
}

#---------------------------------------------------------------------
# Data::Omap::Sorted->order( 'na' ) (or custom sub{})
# set up the comparison subroutine (use $_[0]/$_[1] like $a/$b)

sub order {
    my( $class, $spec ) = @_;  # class not actually used ...
    return $order unless defined $spec;

    if( ref( $spec ) eq 'CODE' ) {
        $order = $spec;
    }
    else {
        $order = {
            ''  => '',                     # turn off ordering
            na  => sub{ $_[0] < $_[1] },   # number ascending
            nd  => sub{ $_[1] < $_[0] },   # number descending
            sa  => sub{ $_[0] lt $_[1] },  # string ascending
            sd  => sub{ $_[1] lt $_[0] },  # string descending
            sna => sub{                    # either ascending
                looks_like_number($_[0])&&looks_like_number($_[1])?
                $_[0] < $_[1]: $_[0] lt $_[1] },
            snd => sub{                    # either descending
                looks_like_number($_[0])&&looks_like_number($_[1])?
                $_[1] < $_[0]: $_[1] lt $_[0] },
            }->{ $spec };
        die "\$spec($spec) not recognized" unless defined $order;
    }
    return $order;
}

#---------------------------------------------------------------------
# object methods
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# $omap->set( $key => $value[, $pos] )
# sets { $key => $value } [at $pos, which overrides order ...]
# return value not defined (XXX yet?)

sub set {
    my( $self, $key, $value, $pos ) = @_;
    return unless defined $key;

    # you can give a $pos to change a member including changing its key
    # ... but not if doing so would duplicate a key in the object

    # pos   found    action
    # ----- -----    ------
    # def   def   -> set key/value at pos (if pos==found)
    # def   undef -> set key/value at pos
    # undef def   -> set key/value at found
    # undef undef -> add key/value according to order

    my $found = $self->get_pos( $key );
    my $elem = { $key => $value };

    if( defined $pos and defined $found ) {
        die "\$key($key) found, but not at \$pos($pos): duplicate keys not allowed"
            if $found != $pos;
        $self->[ $pos ] = $elem;  # pos == found
    }
    elsif( defined $pos )   { $self->[ $pos ]   = $elem }
    elsif( defined $found ) { $self->[ $found ] = $elem }
    else                    { $self->_add_ordered( $key, $value ) }

}

#---------------------------------------------------------------------
# $omap->get( @keys )
# returns values in order found in object

sub get {
    my( $self, @keys ) = @_;
    return unless @$self;
    my @ret;
    if( @keys ) {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            for ( @keys ) {
                if( $key eq $_ ) {
                    my ( $value ) = values %$href;
                    return $value unless wantarray;
                    push @ret, $value;
                    last;
                }
            }
        }
    }
    else {
        for my $href ( @$self ) {
            my ( $value ) = values %$href;
            return $value unless wantarray;  # first value
            push @ret, $value;
        }
    }
    return unless wantarray;
    @ret;  # returned
}

#---------------------------------------------------------------------
# $omap->add( $key => $value[, $pos] )
# adds a member { $key => $value } [at $pos, which overrides order ...]
# return value not defined (XXX yet?)

sub add {
    my( $self, $key, $value, $pos ) = @_;
    return unless defined $key;

    my $found = $self->get_pos( $key );
    die "\$key($key) found: duplicate keys not allowed" if defined $found;

    my $elem = { $key => $value };
    if( defined $pos ) { splice @$self, $pos, 0, $elem }
    else               { $self->_add_ordered( $key, $value ) }
}

#---------------------------------------------------------------------
sub _add_ordered {
    my( $self, $key, $value ) = @_;
    my $elem = { $key => $value };

    unless( $order ) { push @$self, $elem; return }

    # optimization for when members are added in order
    if( @$self ) {
        my ( $key2 ) = keys %{$self->[-1]};
        unless( $order->( $key, $key2 ) ) {
            push @$self, $elem;
            return;
        }
    }

    # else start at the beginning
    for my $i ( 0 .. $#$self ) {
        my ( $key2 ) = keys %{$self->[ $i ]};
        if( $order->( $key, $key2 ) ) {  # XXX how memoize $key in $order->()?
            splice @$self, $i, 0, $elem;
            return;
        }
    }

    push @$self, $elem;
}

#---------------------------------------------------------------------
# $omap->get_pos( @keys )
# returns positions where keys found in object
# positions are returned in the same order as @keys parameter

sub get_pos {
    my( $self, @keys ) = @_;
    return unless @keys;
    return unless @$self;
    my @ret;
    for ( @keys ) {
        for my $i ( 0 .. $#$self ) {
            my ( $key ) = keys %{$self->[ $i ]};
            if( $key eq $_ ) {
                return $i unless wantarray;
                push @ret, $i;
                last;
            }
        }
    }
    return unless wantarray;  # happens only when no keys found
    @ret;  # returned
}

#---------------------------------------------------------------------
# $omap->get_keys( @keys )
# returns keys in order found in object
# scalar context: returns number of keys found

sub get_keys {
    my( $self, @keys ) = @_;
    return unless @$self;
    my @ret;
    if( @keys ) {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            for ( @keys ) {
                if( $key eq $_ ) {
                    push @ret, $key;
                    last;
                }
            }
        }
    }
    else {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            push @ret, $key;
        }
    }
    @ret;  # returned
}

#---------------------------------------------------------------------
# $omap->clone( [@keys] )
# returns clone of self, NOT blessed

sub clone {
    my( $self, @keys ) = @_;
    my $clone = [];
    if( @keys ) {
        for my $href ( @$self ) {
            my ( $key ) = keys %$href;
            for ( @keys ) {
                if( $key eq $_ ) {
                    push @$clone, { %$href };
                    last;
                }
            }
        }
    }
    else {
        for my $href ( @$self ) {
            push @$clone, { %$href };
        }
    }
    $clone;  # returned
}

#---------------------------------------------------------------------
# $omap->firstkey()
# returns first key

sub firstkey {
    my( $self ) = @_;
    return unless @$self;
    my ( $firstkey ) = keys %{$self->[0]};
    $firstkey;  # returned
}

#---------------------------------------------------------------------
# $omap->nextkey( $lastkey )
# XXX want a more efficient solution

sub nextkey {
    my( $self, $lastkey ) = @_;
    return unless @$self;
    for my $i ( 0 .. $#$self ) {
        my ( $key ) = keys %{$self->[ $i ]};
        if( $key eq $lastkey ) {
            return unless defined $self->[ $i+1 ];
            my ( $nextkey ) = keys %{$self->[ $i+1 ]};
            return $nextkey;
        }
    }
}

#---------------------------------------------------------------------
# $omap->exists( key )
# returns true if key found

sub exists {
    my( $self, $key ) = @_;
    return unless @$self;
    return 1 if defined $self->get_pos( $key );
    return;
}

#---------------------------------------------------------------------
# $omap->delete( $key )
# deletes { $key => $value } member
# returns the $value deleted

sub delete {
    my( $self, $key ) = @_;
    return unless defined $key;
    return unless @$self;

    my $found = $self->get_pos( $key );
    return unless defined $found;

    my $value = $self->[ $found ]->{ $key };
    splice @$self, $found, 1;  # delete it

    $value;  # returned
}

#---------------------------------------------------------------------
# $omap->clear()
# removes all members
# returns the $value deleted

sub clear {
    my( $self ) = @_;
    @$self = ();
}

#---------------------------------------------------------------------
# perltie methods
#---------------------------------------------------------------------

# XXX because of the ineficencies in nextkey, keys() and values() may be
# very slow. consider using (tied %hash)->get_keys() or ->get() instead

# TIEHASH classname, LIST
# This is the constructor for the class. That means it is expected to
# return a blessed reference through which the new object (probably but
# not necessarily an anonymous hash) will be accessed.

sub TIEHASH {
    my $class = shift;
    $class->new( @_ );
}

#---------------------------------------------------------------------
# FETCH this, key
# This method will be triggered every time an element in the tied hash
# is accessed (read). 

sub FETCH {
    my $self = shift;
    $self->get( @_ );
}

#---------------------------------------------------------------------
# STORE this, key, value
# This method will be triggered every time an element in the tied hash
# is set (written). 

sub STORE {
    my $self = shift;
    $self->set( @_ );
}

#---------------------------------------------------------------------
# DELETE this, key
# This method is triggered when we remove an element from the hash,
# typically by using the delete() function.
# If you want to emulate the normal behavior of delete(), you should
# return whatever FETCH would have returned for this key. 

sub DELETE {
    my $self = shift;
    $self->delete( @_ );
}

#---------------------------------------------------------------------
# CLEAR this
# This method is triggered when the whole hash is to be cleared,
# usually by assigning the empty list to it.

sub CLEAR {
    my $self = shift;
    $self->clear();
}

#---------------------------------------------------------------------
# EXISTS this, key
# This method is triggered when the user uses the exists() function
# on a particular hash.

sub EXISTS {
    my $self = shift;
    $self->exists( @_ );
}

#---------------------------------------------------------------------
# FIRSTKEY this
# This method will be triggered when the user is going to iterate
# through the hash, such as via a keys() or each() call.

sub FIRSTKEY {
    my $self = shift;
    $self->firstkey();
}

#---------------------------------------------------------------------
# NEXTKEY this, lastkey
# This method gets triggered during a keys() or each() iteration.
# It has a second argument which is the last key that had been accessed.

sub NEXTKEY {
    my $self = shift;
    $self->nextkey( @_ );
}

#---------------------------------------------------------------------
# SCALAR this
# This is called when the hash is evaluated in scalar context.
# In order to mimic the behaviour of untied hashes, this method should
# return a false value when the tied hash is considered empty.

sub SCALAR {
    my $self = shift;
    $self->get_keys();  # number of keys or undef
}

#---------------------------------------------------------------------
# UNTIE this
# This is called when untie occurs. See "The untie Gotcha".

# sub UNTIE {
# }

#---------------------------------------------------------------------
# DESTROY this
# This method is triggered when a tied hash is about to go out of scope.

# sub DESTROY {
# }

#---------------------------------------------------------------------

1;  # use module return

__END__

