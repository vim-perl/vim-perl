use strict;
use warnings;

use Test::Requires {
    'Test::Output' => '0.01',
};

use Test::More;

{
    package Parent;
    use Moose;

    sub foo { 42 }
    sub bar { 42 }

    package Child;
    use Moose;

    extends 'Parent';

    override foo => sub {
        super( 1, 2, 3 );
    };

    override bar => sub {
        super();
    };
}

{
    my $file = __FILE__;

    stderr_like(
        sub { Child->new->foo },
        qr/\QArguments passed to super() are ignored at $file/,
        'got a warning when passing args to super() call'
    );

    stderr_is(
        sub { Child->new->bar },
        q{},
        'no warning on super() call without arguments'
    );
}

done_testing();
