use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;
use Class::MOP::Method;

# test before and afters
{
    my $trace = '';

    my $method = Class::MOP::Method->wrap(
        body => sub { $trace .= 'primary' },
        package_name => 'main',
        name         => '__ANON__',
    );
    isa_ok( $method, 'Class::MOP::Method' );

    $method->();
    is( $trace, 'primary', '... got the right return value from method' );
    $trace = '';

    my $wrapped = Class::MOP::Method::Wrapped->wrap($method);
    isa_ok( $wrapped, 'Class::MOP::Method::Wrapped' );
    isa_ok( $wrapped, 'Class::MOP::Method' );

    $wrapped->();
    is( $trace, 'primary',
        '... got the right return value from the wrapped method' );
    $trace = '';

    is( exception {
        $wrapped->add_before_modifier( sub { $trace .= 'before -> ' } );
    }, undef, '... added the before modifier okay' );

    $wrapped->();
    is( $trace, 'before -> primary',
        '... got the right return value from the wrapped method (w/ before)'
    );
    $trace = '';

    is( exception {
        $wrapped->add_after_modifier( sub { $trace .= ' -> after' } );
    }, undef, '... added the after modifier okay' );

    $wrapped->();
    is( $trace, 'before -> primary -> after',
        '... got the right return value from the wrapped method (w/ before)'
    );
    $trace = '';
}

# test around method
{
    my $method = Class::MOP::Method->wrap(
        sub {4},
        package_name => 'main',
        name         => '__ANON__',
    );
    isa_ok( $method, 'Class::MOP::Method' );

    is( $method->(), 4, '... got the right value from the wrapped method' );

    my $wrapped = Class::MOP::Method::Wrapped->wrap($method);
    isa_ok( $wrapped, 'Class::MOP::Method::Wrapped' );
    isa_ok( $wrapped, 'Class::MOP::Method' );

    is( $wrapped->(), 4, '... got the right value from the wrapped method' );

    is( exception {
        $wrapped->add_around_modifier( sub { ( 3, $_[0]->() ) } );
        $wrapped->add_around_modifier( sub { ( 2, $_[0]->() ) } );
        $wrapped->add_around_modifier( sub { ( 1, $_[0]->() ) } );
        $wrapped->add_around_modifier( sub { ( 0, $_[0]->() ) } );
    }, undef, '... added the around modifier okay' );

    is_deeply(
        [ $wrapped->() ],
        [ 0, 1, 2, 3, 4 ],
        '... got the right results back from the around methods (in list context)'
    );

    is( scalar $wrapped->(), 4,
        '... got the right results back from the around methods (in scalar context)'
    );
}

{
    my @tracelog;

    my $method = Class::MOP::Method->wrap(
        sub { push @tracelog => 'primary' },
        package_name => 'main',
        name         => '__ANON__',
    );
    isa_ok( $method, 'Class::MOP::Method' );

    my $wrapped = Class::MOP::Method::Wrapped->wrap($method);
    isa_ok( $wrapped, 'Class::MOP::Method::Wrapped' );
    isa_ok( $wrapped, 'Class::MOP::Method' );

    is( exception {
        $wrapped->add_before_modifier( sub { push @tracelog => 'before 1' } );
        $wrapped->add_before_modifier( sub { push @tracelog => 'before 2' } );
        $wrapped->add_before_modifier( sub { push @tracelog => 'before 3' } );
    }, undef, '... added the before modifier okay' );

    is( exception {
        $wrapped->add_around_modifier(
            sub { push @tracelog => 'around 1'; $_[0]->(); } );
        $wrapped->add_around_modifier(
            sub { push @tracelog => 'around 2'; $_[0]->(); } );
        $wrapped->add_around_modifier(
            sub { push @tracelog => 'around 3'; $_[0]->(); } );
    }, undef, '... added the around modifier okay' );

    is( exception {
        $wrapped->add_after_modifier( sub { push @tracelog => 'after 1' } );
        $wrapped->add_after_modifier( sub { push @tracelog => 'after 2' } );
        $wrapped->add_after_modifier( sub { push @tracelog => 'after 3' } );
    }, undef, '... added the after modifier okay' );

    $wrapped->();
    is_deeply(
        \@tracelog,
        [
            'before 3', 'before 2', 'before 1',    # last-in-first-out order
            'around 3', 'around 2', 'around 1',    # last-in-first-out order
            'primary',
            'after 1', 'after 2', 'after 3',       # first-in-first-out order
        ],
        '... got the right tracelog from all our before/around/after methods'
    );
}

# test introspection
{
    sub before1 {
    }

    sub before2 {
    }

    sub before3 {
    }

    sub after1 {
    }

    sub after2 {
    }

    sub after3 {
    }

    sub around1 {
    }

    sub around2 {
    }

    sub around3 {
    }

    sub orig {
    }

    my $method = Class::MOP::Method->wrap(
        body         => \&orig,
        package_name => 'main',
        name         => '__ANON__',
    );

    my $wrapped = Class::MOP::Method::Wrapped->wrap($method);

    $wrapped->add_before_modifier($_)
        for \&before1, \&before2, \&before3;

    $wrapped->add_after_modifier($_)
        for \&after1, \&after2, \&after3;

    $wrapped->add_around_modifier($_)
        for \&around1, \&around2, \&around3;

    is( $wrapped->get_original_method, $method,
        'check get_original_method' );

    is_deeply( [ $wrapped->before_modifiers ],
               [ \&before3, \&before2, \&before1 ],
               'check before_modifiers' );

    is_deeply( [ $wrapped->after_modifiers ],
               [ \&after1, \&after2, \&after3 ],
               'check after_modifiers' );

    is_deeply( [ $wrapped->around_modifiers ],
               [ \&around3, \&around2, \&around1 ],
               'check around_modifiers' );
}

done_testing;
