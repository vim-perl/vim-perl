use strict;
use warnings;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

package FooArray;
sub new    { bless [], shift }
sub foo    { }

package FooScalar;
sub new    { my $val = 42; bless \$val, shift }
sub foo    { }

package FooCode;
sub new    { my $ref = sub {}; bless $ref, shift }
sub foo    { }

package main;
use Test::More;
use Data::Printer;
my $scalar = FooScalar->new;
my $array  = FooArray->new;
my $code   = FooCode->new;

is( p($scalar), 'FooScalar  {
    public methods (2) : foo, new
    private methods (0)
    internals: 42
}', 'testing blessed scalar' );

is( p($array ), 
'FooArray  {
    public methods (2) : foo, new
    private methods (0)
    internals: []
}', 'testing blessed array' );

SKIP: {
    skip 'no internals in blessed subs yet', 1;

is( p($code), 
'FooCode  {
    public methods (2) : foo, new
    private methods (0)
    internals: sub { ... }
}', 'testing blessed code' );

};

is( p($scalar, class => { show_reftype => 1 } ),
   'FooScalar (SCALAR)  {
    public methods (2) : foo, new
    private methods (0)
    internals: 42
}', 'testing blessed scalar with reftype' );

done_testing;
