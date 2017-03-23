use strict;
use warnings;

use Test::More;

BEGIN {
    use Test::More;
    plan skip_all => 'These tests are only for Test::Builder 1.005+'
        if Test::Builder->VERSION < 1.005;
}

{
    package Foo;
    use Moose;
}

{
    package Bar;
    use Moose;
}

package main;

use Test::Moose;
use TB2::Tester;
use TB2::History;   # FIXME - this should not need to be loaded here explicitly

my ($ret1, $ret2);
my $capture = capture {
    $ret1 = with_immutable {
        ok(Foo->meta->is_mutable, 'is mutable');
    } qw(Foo);

    $ret2 = with_immutable {
        ok(Bar->meta->find_method_by_name('new'), 'can find "new" method');
    } qw(Bar);
};

my $results = $capture->results;

my @tests = (
    [
        'first test runs while Foo is mutable' => { name => 'is mutable',
                                                    is_pass => 1,
                                                   },
    ],
    [
        'first test runs while Foo is immutable' => { name => 'is mutable',
                                                      is_pass => 0,
                                                    },
    ],
    [
        'can find "new" while Bar is mutable'   => { name => 'can find "new" method',
                                                     is_pass => 1,
                                                   },
    ],
    [
        'can find "new" while Bar is immutable' => { name => 'can find "new" method',
                                                     is_pass => 1,
                                                   },
    ],
);

result_like(shift(@$results), $_->[1], $_->[0]) foreach @tests;

ok(!$ret1, 'one of the is_immutable tests failed');
ok($ret2, 'the find_method_by_name tests passed');

done_testing;

