use strict;
use warnings;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

package Bar;
sub bar    { }
sub borg   { }
sub _moo   { }

1;

package Foo;
our @ISA = qw(Bar);

sub new    { bless { test => 42 }, shift }
sub foo    { }
sub baz    { }
sub borg   { $_[0]->{borg} = $_[1]; }
sub _other { }

1;

package Baz;
sub bar { 42 }

1;

package Meep;
our @ISA = qw(Foo Baz);

1;

package ParentLess;
sub new    { bless {}, shift }

1;

package main;
use Test::More;
use Data::Printer;

my $obj = Foo->new;

is( p($obj), 'Foo  {
    Parents       Bar
    public methods (4) : baz, borg, foo, new
    private methods (1) : _other
    internals: {
        test   42
    }
}', 'testing objects' );

is( p($obj, class => { linear_isa => 1 }), 'Foo  {
    Parents       Bar
    Linear @ISA   Foo, Bar
    public methods (4) : baz, borg, foo, new
    private methods (1) : _other
    internals: {
        test   42
    }
}', 'testing objects, forcing linear @ISA' );

is( p($obj, class => { parents => 0 }), 'Foo  {
    public methods (4) : baz, borg, foo, new
    private methods (1) : _other
    internals: {
        test   42
    }
}', 'testing objects (parents => 0)' );

is( p($obj, class => { show_methods => 'none' }), 'Foo  {
    Parents       Bar
    internals: {
        test   42
    }
}', 'testing objects (no methods)' );

is( p($obj, class => { show_methods => 'public' }), 'Foo  {
    Parents       Bar
    public methods (4) : baz, borg, foo, new
    internals: {
        test   42
    }
}', 'testing objects (only public methods)' );

is( p($obj, class => { show_methods => 'private' }), 'Foo  {
    Parents       Bar
    private methods (1) : _other
    internals: {
        test   42
    }
}', 'testing objects (only private methods)' );

is( p($obj, class => { show_methods => 'all' }), 'Foo  {
    Parents       Bar
    public methods (4) : baz, borg, foo, new
    private methods (1) : _other
    internals: {
        test   42
    }
}', 'testing objects (explicitly asking for all methods)' );

is( p($obj, class => { internals => 0 } ), 
'Foo  {
    Parents       Bar
    public methods (4) : baz, borg, foo, new
    private methods (1) : _other
}', 'testing objects (no internals)' );

is( p($obj, class => { inherited => 0 }), 'Foo  {
    Parents       Bar
    public methods (4) : baz, borg, foo, new
    private methods (1) : _other
    internals: {
        test   42
    }
}', 'testing objects (inherited => 0)' );

my ($n, $extra_field) = $] < 5.010 ? (8, '') : (9, ' DOES (UNIVERSAL),');

is( p($obj, class => { inherited => 'all' }), "Foo  {
    Parents       Bar
    public methods ($n) : bar (Bar), baz, borg, can (UNIVERSAL),$extra_field foo, isa (UNIVERSAL), new, VERSION (UNIVERSAL)
    private methods (2) : _moo (Bar), _other
    internals: {
        test   42
    }
}", 'testing objects (inherited => "all")' );

is( p($obj, class => { inherited => 'all', universal => 0 }), "Foo  {
    Parents       Bar
    public methods (5) : bar (Bar), baz, borg, foo, new
    private methods (2) : _moo (Bar), _other
    internals: {
        test   42
    }
}", 'testing objects (inherited => "all", universal => 0)' );

is( p($obj, class => { inherited => 'public' }), "Foo  {
    Parents       Bar
    public methods ($n) : bar (Bar), baz, borg, can (UNIVERSAL),$extra_field foo, isa (UNIVERSAL), new, VERSION (UNIVERSAL)
    private methods (1) : _other
    internals: {
        test   42
    }
}", 'testing objects (inherited => "public")' );

is( p($obj, class => { inherited => 'public', universal => 0 }), "Foo  {
    Parents       Bar
    public methods (5) : bar (Bar), baz, borg, foo, new
    private methods (1) : _other
    internals: {
        test   42
    }
}", 'testing objects (inherited => "public", universal => 0)' );

is( p($obj, class => { inherited => 'private' }), 'Foo  {
    Parents       Bar
    public methods (4) : baz, borg, foo, new
    private methods (2) : _moo (Bar), _other
    internals: {
        test   42
    }
}', 'testing objects (inherited => "private")' );

is( p($obj, class => { expand => 0 }), 'Foo',
    'testing objects without expansion' );

$obj->borg( Foo->new );

is( p($obj), 'Foo  {
    Parents       Bar
    public methods (4) : baz, borg, foo, new
    private methods (1) : _other
    internals: {
        borg   Foo,
        test   42
    }
}', 'testing nested objects' );

is( p($obj, class => { expand => 'all'} ), 'Foo  {
    Parents       Bar
    public methods (4) : baz, borg, foo, new
    private methods (1) : _other
    internals: {
        borg   Foo  {
            Parents       Bar
            public methods (4) : baz, borg, foo, new
            private methods (1) : _other
            internals: {
                test   42
            }
        },
        test   42
    }
}', 'testing nested objects with expansion' );

my $obj_with_isa = Meep->new;

is( p($obj_with_isa), 'Meep  {
    Parents       Foo, Baz
    Linear @ISA   Meep, Foo, Bar, Baz
    public methods (0)
    private methods (0)
    internals: {
        test   42
    }
}', 'testing objects with @ISA' );

is( p($obj_with_isa, class => { linear_isa => 0 }), 'Meep  {
    Parents       Foo, Baz
    public methods (0)
    private methods (0)
    internals: {
        test   42
    }
}', 'testing objects with @ISA, opting out the @ISA' );

is( p($obj_with_isa, class => { linear_isa => 0 }), 'Meep  {
    Parents       Foo, Baz
    public methods (0)
    private methods (0)
    internals: {
        test   42
    }
}', 'testing objects with @ISA' );

my $parentless = ParentLess->new;

is( p($parentless), 'ParentLess  {
    public methods (1) : new
    private methods (0)
    internals: {}
}', 'testing parentless object' );

done_testing;
