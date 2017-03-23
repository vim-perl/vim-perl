use strict;
use warnings;

use Test::More;

{
    package A;
    use Moose;

    sub foo {
        ::BAIL_OUT('A::foo called twice') if $main::seen{'A::foo'}++;
        return 'a';
    }

    sub bar {
        ::BAIL_OUT('A::bar called twice') if $main::seen{'A::bar'}++;
        return 'a';
    }

    sub baz {
        ::BAIL_OUT('A::baz called twice') if $main::seen{'A::baz'}++;
        return 'a';
    }
}

{
    package B;
    use Moose;
    extends qw(A);

    sub foo {
        ::BAIL_OUT('B::foo called twice') if $main::seen{'B::foo'}++;
        return 'b' . super();
    }

    sub bar {
        ::BAIL_OUT('B::bar called twice') if $main::seen{'B::bar'}++;
        return 'b' . ( super() || '' );
    }

    override baz => sub {
        ::BAIL_OUT('B::baz called twice') if $main::seen{'B::baz'}++;
        return 'b' . super();
    };
}

{
    package C;
    use Moose;
    extends qw(B);

    sub foo { return 'c' . ( super() || '' ) }

    override bar => sub {
        ::BAIL_OUT('C::bar called twice') if $main::seen{'C::bar'}++;
        return 'c' . super();
    };

    override baz => sub {
        ::BAIL_OUT('C::baz called twice') if $main::seen{'C::baz'}++;
        return 'c' . super();
    };
}

is( C->new->foo, 'c' );
is( C->new->bar, 'cb' );
is( C->new->baz, 'cba' );

done_testing;
