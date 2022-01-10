use strict;
use warnings;

use Test::More;

{

    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'UCHash', as 'HashRef[Str]', where {
        !grep {/[a-z]/} values %{$_};
    };

    coerce 'UCHash', from 'HashRef[Str]', via {
        $_ = uc $_ for values %{$_};
        $_;
    };

    has hash => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'UCHash',
        coerce  => 1,
        handles => {
            set_key => 'set',
        },
    );

    our @TriggerArgs;

    has lazy => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'UCHash',
        coerce  => 1,
        lazy    => 1,
        default => sub { { x => 'a' } },
        handles => {
            set_lazy => 'set',
        },
        trigger => sub { @TriggerArgs = @_ },
        clearer => 'clear_lazy',
    );
}

my $foo = Foo->new;

{
    $foo->hash( { x => 'A', y => 'B' } );

    $foo->set_key( z => 'c' );

    is_deeply(
        $foo->hash, { x => 'A', y => 'B', z => 'C' },
        'set coerces the hash'
    );
}

{
    $foo->set_lazy( y => 'b' );

    is_deeply(
        $foo->lazy, { x => 'A', y => 'B' },
        'set coerces the hash - lazy'
    );

    is_deeply(
        \@Foo::TriggerArgs,
        [ $foo, { x => 'A', y => 'B' }, { x => 'A' } ],
        'trigger receives expected arguments'
    );
}

{
    package Thing;
    use Moose;

    has thing => (
        is  => 'ro',
        isa => 'Str',
    );
}

{
    package Bar;
    use Moose;
    use Moose::Util::TypeConstraints;

    class_type 'Thing';

    coerce 'Thing'
        => from 'Str'
        => via { Thing->new( thing => $_ ) };

    subtype 'HashRefOfThings'
        => as 'HashRef[Thing]';

    coerce 'HashRefOfThings'
        => from 'HashRef[Str]'
        => via {
            my %new;
            for my $k ( keys %{$_} ) {
                $new{$k} = Thing->new( thing => $_->{$k} );
            }
            return \%new;
        };

    coerce 'HashRefOfThings'
        => from 'Str'
        => via { [ Thing->new( thing => $_ ) ] };

    has hash => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'HashRefOfThings',
        coerce  => 1,
        handles => {
            set_hash => 'set',
            get_hash => 'get',
        },
    );
}

{
    my $bar = Bar->new( hash => { foo => 1, bar => 2 } );

    is(
        $bar->get_hash('foo')->thing, 1,
        'constructor coerces hash reference'
    );

    $bar->set_hash( baz => 3, quux => 4 );

    is(
        $bar->get_hash('baz')->thing, 3,
        'set coerces new hash values'
    );

    is(
        $bar->get_hash('quux')->thing, 4,
        'set coerces new hash values'
    );
}


done_testing;
