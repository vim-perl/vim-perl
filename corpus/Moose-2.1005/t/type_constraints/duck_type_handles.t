#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my @phonograph;
{
    package Duck;
    use Moose;

    sub walk {
        push @phonograph, 'footsteps',
    }

    sub quack {
        push @phonograph, 'quack';
    }

    package Swan;
    use Moose;

    sub honk {
        push @phonograph, 'honk';
    }

    package DucktypeTest;
    use Moose;
    use Moose::Util::TypeConstraints;

    my $ducktype = duck_type 'DuckType' => qw(walk quack);

    has duck => (
        isa     => $ducktype,
        handles => $ducktype,
    );
}

my $t = DucktypeTest->new(duck => Duck->new);
$t->quack;
is_deeply([splice @phonograph], ['quack']);

$t->walk;
is_deeply([splice @phonograph], ['footsteps']);

done_testing;
