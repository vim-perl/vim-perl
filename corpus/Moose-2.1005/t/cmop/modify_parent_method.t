use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

my @calls;

{
    package Parent;

    use strict;
    use warnings;
    use metaclass;

    use Carp 'confess';

    sub method { push @calls, 'Parent::method' }

    package Child;

    use strict;
    use warnings;
    use metaclass;

    use base 'Parent';

    Child->meta->add_around_method_modifier(
        'method' => sub {
            my $orig = shift;
            push @calls, 'before Child::method';
            $orig->(@_);
            push @calls, 'after Child::method';
        }
    );
}

Parent->method;

is_deeply(
    [ splice @calls ],
    [
        'Parent::method',
    ]
);

Child->method;

is_deeply(
    [ splice @calls ],
    [
        'before Child::method',
        'Parent::method',
        'after Child::method',
    ]
);

{
    package Parent;

    Parent->meta->add_around_method_modifier(
        'method' => sub {
            my $orig = shift;
            push @calls, 'before Parent::method';
            $orig->(@_);
            push @calls, 'after Parent::method';
        }
    );
}

Parent->method;

is_deeply(
    [ splice @calls ],
    [
        'before Parent::method',
        'Parent::method',
        'after Parent::method',
    ]
);

Child->method;

TODO: {
    local $TODO = "pending fix";
    is_deeply(
        [ splice @calls ],
        [
            'before Child::method',
            'before Parent::method',
            'Parent::method',
            'after Parent::method',
            'after Child::method',
        ],
        "cache is correctly invalidated when the parent method is wrapped"
    );
}

done_testing;
