use strict;
use warnings;
use Test::More;

{
    package FooBar;
    use Moose;

    has 'name' => ( is => 'ro' );

    sub DESTROY { shift->name }

    local $SIG{__WARN__} = sub {};
    __PACKAGE__->meta->make_immutable;
}

my $f = FooBar->new( name => 'SUSAN' );

is( $f->DESTROY, 'SUSAN', 'Did moose overload DESTROY?' );

done_testing;
