use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Test::Requires {
    'Test::Output' => '0.01',
};

# All tests are wrapped with lives_and because the stderr output tests will
# otherwise eat exceptions, and the test just dies silently.

{
    package Role;

    use Moose::Role;

    sub thing { }
}

{
    package Foo;

    use Moose;

    ::is( ::exception (
        sub {
            ::stderr_like{ has foo => (
                    traits => ['String'],
                    is     => 'ro',
                    isa    => 'Str',
                );
                }
                qr{\QAllowing a native trait to automatically supply a default is deprecated. You can avoid this warning by supplying a default, builder, or making the attribute required at $0 line},
                'Not providing a default for native String trait warns';

            ::stderr_is{ has bar => (
                    traits  => ['Bool'],
                    isa     => 'Bool',
                    default => q{},
                );
                } q{}, 'No warning when _default_is is set';

            ::stderr_like{ Foo->new->bar }
                qr{\QThe bar method in the Foo class was automatically created by the native delegation trait for the bar attribute. This "default is" feature is deprecated. Explicitly set "is" or define accessor names to avoid this at $0 line},
                'calling a reader on a method created by a _default_is warns';
        }
    ), undef );
}

{
    package Pack1;

    use Moose;

    ::is( ::exception (
        sub {
            ::stderr_is{ has foo => (
                    traits  => ['String'],
                    is      => 'ro',
                    isa     => 'Str',
                    builder => '_build_foo',
                );
                } q{},
                'Providing a builder for a String trait avoids default default warning';

            has bar => (
                traits  => ['String'],
                reader  => '_bar',
                isa     => 'Str',
                default => q{},
            );

            ::ok(
                !Pack1->can('bar'),
                'no default is assigned when reader is provided'
            );

            ::stderr_is{ Pack1->new->_bar } q{},
                'Providing a reader for a String trait avoids default is warning';
        }
    ), undef );

    sub _build_foo { q{} }
}

{
    package Pack2;

    use Moose;

    ::is( ::exception (
        sub {
            ::stderr_is{ has foo => (
                    traits   => ['String'],
                    is       => 'ro',
                    isa      => 'Str',
                    required => 1,
                );
                } q{},
                'Making a String trait required avoids default default warning';

            has bar => (
                traits  => ['String'],
                writer  => '_bar',
                isa     => 'Str',
                default => q{},
            );

            ::ok(
                !Pack2->can('bar'),
                'no default is assigned when writer is provided'
            );

            ::stderr_is{ Pack2->new( foo => 'x' )->_bar('x') }
                q{},
                'Providing a writer for a String trait avoids default is warning';
        }
    ), undef );
}

{
    package Pack3;

    use Moose;

    ::is( ::exception (
        sub {
            ::stderr_is{ has foo => (
                    traits     => ['String'],
                    is         => 'ro',
                    isa        => 'Str',
                    lazy_build => 1,
                );
                } q{},
                'Making a String trait lazy_build avoids default default warning';

            has bar => (
                traits   => ['String'],
                accessor => '_bar',
                isa      => 'Str',
                default  => q{},
            );

            ::ok(
                !Pack3->can('bar'),
                'no default is assigned when accessor is provided'
            );

            ::stderr_is{ Pack3->new->_bar }
                q{},
                'Providing a accessor for a String trait avoids default is warning';
        }
    ), undef );

    sub _build_foo { q{} }
}

{
    use Moose::Util::TypeConstraints;

    is(
        exception {
            stderr_like {
                subtype 'Frubble', as 'Str', optimize_as sub { };
            }
            qr/\QProviding an optimized subroutine ref for type constraints is deprecated./,
            'Providing an optimize_as sub is deprecated';
        },
        undef
    );
}

done_testing;

