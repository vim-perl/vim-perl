use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer {
    filters => {
        'My::Module'    => sub { $_[0]->test },
        'SCALAR'        => sub { 'found!!' },
        -class          => sub { '1, 2, 3' },
        'ARRAY'         => sub {
           my $ref = shift;
           return join ':', map { p(\$_) } @$ref;
        },
        'HASH' => sub {
            my $ref = shift;
            return 'list => ' . p($ref->{items});
        },
    },
};

package My::Module;
sub new { bless {}, shift }
sub test { return 'this is a test' }

package Other::Module;
sub new { bless {}, shift }

package main;

my $obj = My::Module->new;

is( p($obj), 'this is a test', 'testing filter for object' );
is p($obj, filters => { 'My::Module' => sub { return 'mo' }}), 'mo', 'overriding My::Module filter';
is p($obj), 'this is a test', 'testing filter restoration for object';
is p($obj, filters => { 'My::Module' => sub { return } }), 'this is a test', 'filter override with fallback';

my $obj2 = Other::Module->new;
is p($obj2, filters => { 'Other::Module' => sub { return } }), '1, 2, 3',
   '-class filters can have a go if specific filter failed';

my $scalar = 42;
is( p($scalar), 'found!!', 'testing filter for SCALAR' );

is( p($scalar, filters => { SCALAR => sub { return 'a' } }), 'a', 'overriding SCALAR filter' );

is( p($scalar), 'found!!', "inline filters shouldn't stick" );

is( p($scalar, filters => { SCALAR => sub { return } }), 'found!!', 'SCALAR filter fallback' );

my $scalar_ref = \$scalar;
is( p($scalar_ref), '\\ found!!', 'testing filter for SCALAR (passing a ref instead)' );

my @list = (1 .. 3);
is( p(@list), 'found!!:found!!:found!!', 'testing filters referencing p()' );

my %hash = ( items => \@list );
is( p(%hash), 'list => found!!:found!!:found!!', 'testing filters passing a list into p()' );

done_testing;
