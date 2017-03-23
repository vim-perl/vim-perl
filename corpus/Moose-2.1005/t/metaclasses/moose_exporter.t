#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

use Test::Requires {
    'Test::Output' => '0.01', # skip all if not installed
};

{
    package HasOwnImmutable;

    use Moose;

    no Moose;

    ::stderr_is( sub { eval q[sub make_immutable { return 'foo' }] },
                  '',
                  'no warning when defining our own make_immutable sub' );
}

{
    is( HasOwnImmutable->make_immutable(), 'foo',
        'HasOwnImmutable->make_immutable does not get overwritten' );
}

{
    package MooseX::Empty;

    use Moose ();
    Moose::Exporter->setup_import_methods( also => 'Moose' );
}

{
    package WantsMoose;

    MooseX::Empty->import();

    sub foo { 1 }

    ::can_ok( 'WantsMoose', 'has' );
    ::can_ok( 'WantsMoose', 'with' );
    ::can_ok( 'WantsMoose', 'foo' );

    MooseX::Empty->unimport();
}

{
    # Note: it's important that these methods be out of scope _now_,
    # after unimport was called. We tried a
    # namespace::clean(0.08)-based solution, but had to abandon it
    # because it cleans the namespace _later_ (when the file scope
    # ends).
    ok( ! WantsMoose->can('has'),  'WantsMoose::has() has been cleaned' );
    ok( ! WantsMoose->can('with'), 'WantsMoose::with() has been cleaned' );
    can_ok( 'WantsMoose', 'foo' );

    # This makes sure that Moose->init_meta() happens properly
    isa_ok( WantsMoose->meta(), 'Moose::Meta::Class' );
    isa_ok( WantsMoose->new(), 'Moose::Object' );

}

{
    package MooseX::Sugar;

    use Moose ();

    sub wrapped1 {
        my $meta = shift;
        return $meta->name . ' called wrapped1';
    }

    Moose::Exporter->setup_import_methods(
        with_meta => ['wrapped1'],
        also      => 'Moose',
    );
}

{
    package WantsSugar;

    MooseX::Sugar->import();

    sub foo { 1 }

    ::can_ok( 'WantsSugar', 'has' );
    ::can_ok( 'WantsSugar', 'with' );
    ::can_ok( 'WantsSugar', 'wrapped1' );
    ::can_ok( 'WantsSugar', 'foo' );
    ::is( wrapped1(), 'WantsSugar called wrapped1',
          'wrapped1 identifies the caller correctly' );

    MooseX::Sugar->unimport();
}

{
    ok( ! WantsSugar->can('has'),  'WantsSugar::has() has been cleaned' );
    ok( ! WantsSugar->can('with'), 'WantsSugar::with() has been cleaned' );
    ok( ! WantsSugar->can('wrapped1'), 'WantsSugar::wrapped1() has been cleaned' );
    can_ok( 'WantsSugar', 'foo' );
}

{
    package MooseX::MoreSugar;

    use Moose ();

    sub wrapped2 {
        my $caller = shift->name;
        return $caller . ' called wrapped2';
    }

    sub as_is1 {
        return 'as_is1';
    }

    Moose::Exporter->setup_import_methods(
        with_meta => ['wrapped2'],
        as_is     => ['as_is1'],
        also      => 'MooseX::Sugar',
    );
}

{
    package WantsMoreSugar;

    MooseX::MoreSugar->import();

    sub foo { 1 }

    ::can_ok( 'WantsMoreSugar', 'has' );
    ::can_ok( 'WantsMoreSugar', 'with' );
    ::can_ok( 'WantsMoreSugar', 'wrapped1' );
    ::can_ok( 'WantsMoreSugar', 'wrapped2' );
    ::can_ok( 'WantsMoreSugar', 'as_is1' );
    ::can_ok( 'WantsMoreSugar', 'foo' );
    ::is( wrapped1(), 'WantsMoreSugar called wrapped1',
          'wrapped1 identifies the caller correctly' );
    ::is( wrapped2(), 'WantsMoreSugar called wrapped2',
          'wrapped2 identifies the caller correctly' );
    ::is( as_is1(), 'as_is1',
          'as_is1 works as expected' );

    MooseX::MoreSugar->unimport();
}

{
    ok( ! WantsMoreSugar->can('has'),  'WantsMoreSugar::has() has been cleaned' );
    ok( ! WantsMoreSugar->can('with'), 'WantsMoreSugar::with() has been cleaned' );
    ok( ! WantsMoreSugar->can('wrapped1'), 'WantsMoreSugar::wrapped1() has been cleaned' );
    ok( ! WantsMoreSugar->can('wrapped2'), 'WantsMoreSugar::wrapped2() has been cleaned' );
    ok( ! WantsMoreSugar->can('as_is1'), 'WantsMoreSugar::as_is1() has been cleaned' );
    can_ok( 'WantsMoreSugar', 'foo' );
}

{
    package My::Metaclass;
    use Moose;
    BEGIN { extends 'Moose::Meta::Class' }

    package My::Object;
    use Moose;
    BEGIN { extends 'Moose::Object' }

    package HasInitMeta;

    use Moose ();

    sub init_meta {
        shift;
        return Moose->init_meta( @_,
                                 metaclass  => 'My::Metaclass',
                                 base_class => 'My::Object',
                               );
    }

    Moose::Exporter->setup_import_methods( also => 'Moose' );
}

{
    package NewMeta;

    HasInitMeta->import();
}

{
    isa_ok( NewMeta->meta(), 'My::Metaclass' );
    isa_ok( NewMeta->new(), 'My::Object' );
}

{
    package MooseX::CircularAlso;

    use Moose ();

    ::like(
        ::exception{ Moose::Exporter->setup_import_methods(
                also => [ 'Moose', 'MooseX::CircularAlso' ],
            );
            },
        qr/\QCircular reference in 'also' parameter to Moose::Exporter between MooseX::CircularAlso and MooseX::CircularAlso/,
        'a circular reference in also dies with an error'
    );
}

{
    package MooseX::NoAlso;

    use Moose ();

    ::like(
        ::exception{ Moose::Exporter->setup_import_methods(
                also => ['NoSuchThing'],
            );
            },
        qr/\QPackage in also (NoSuchThing) does not seem to use Moose::Exporter (is it loaded?) at /,
        'a package which does not use Moose::Exporter in also dies with an error'
    );
}

{
    package MooseX::NotExporter;

    use Moose ();

    ::like(
        ::exception{ Moose::Exporter->setup_import_methods(
                also => ['Moose::Meta::Method'],
            );
            },
        qr/\QPackage in also (Moose::Meta::Method) does not seem to use Moose::Exporter at /,
        'a package which does not use Moose::Exporter in also dies with an error'
    );
}

{
    package MooseX::OverridingSugar;

    use Moose ();

    sub has {
        my $caller = shift->name;
        return $caller . ' called has';
    }

    Moose::Exporter->setup_import_methods(
        with_meta => ['has'],
        also      => 'Moose',
    );
}

{
    package WantsOverridingSugar;

    MooseX::OverridingSugar->import();

    ::can_ok( 'WantsOverridingSugar', 'has' );
    ::can_ok( 'WantsOverridingSugar', 'with' );
    ::is( has('foo'), 'WantsOverridingSugar called has',
          'has from MooseX::OverridingSugar is called, not has from Moose' );

    MooseX::OverridingSugar->unimport();
}

{
    ok( ! WantsOverridingSugar->can('has'),  'WantsSugar::has() has been cleaned' );
    ok( ! WantsOverridingSugar->can('with'), 'WantsSugar::with() has been cleaned' );
}

{
    package MooseX::OverridingSugar::PassThru;

    sub with {
        my $caller = shift->name;
        return $caller . ' called with';
    }

    Moose::Exporter->setup_import_methods(
        with_meta => ['with'],
        also      => 'MooseX::OverridingSugar',
    );
}

{

    package WantsOverridingSugar::PassThru;

    MooseX::OverridingSugar::PassThru->import();

    ::can_ok( 'WantsOverridingSugar::PassThru', 'has' );
    ::can_ok( 'WantsOverridingSugar::PassThru', 'with' );
    ::is(
        has('foo'),
        'WantsOverridingSugar::PassThru called has',
        'has from MooseX::OverridingSugar is called, not has from Moose'
    );

    ::is(
        with('foo'),
        'WantsOverridingSugar::PassThru called with',
        'with from MooseX::OverridingSugar::PassThru is called, not has from Moose'
    );


    MooseX::OverridingSugar::PassThru->unimport();
}

{
    ok( ! WantsOverridingSugar::PassThru->can('has'),  'WantsOverridingSugar::PassThru::has() has been cleaned' );
    ok( ! WantsOverridingSugar::PassThru->can('with'), 'WantsOverridingSugar::PassThru::with() has been cleaned' );
}

{

    package NonExistentExport;

    use Moose ();

    ::stderr_like {
        Moose::Exporter->setup_import_methods(
            also => ['Moose'],
            with_meta => ['does_not_exist'],
        );
    } qr/^Trying to export undefined sub NonExistentExport::does_not_exist/,
      "warns when a non-existent method is requested to be exported";
}

{
    package WantsNonExistentExport;

    NonExistentExport->import;

    ::ok(!__PACKAGE__->can('does_not_exist'),
         "undefined subs do not get exported");
}

{
    package AllOptions;
    use Moose ();
    use Moose::Deprecated -api_version => '0.88';
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        also        => ['Moose'],
        with_meta   => [ 'with_meta1', 'with_meta2' ],
        with_caller => [ 'with_caller1', 'with_caller2' ],
        as_is       => ['as_is1'],
    );

    sub with_caller1 {
        return @_;
    }

    sub with_caller2 (&) {
        return @_;
    }

    sub as_is1 {2}

    sub with_meta1 {
        return @_;
    }

    sub with_meta2 (&) {
        return @_;
    }
}

{
    package UseAllOptions;

    AllOptions->import();
}

{
    can_ok( 'UseAllOptions', $_ )
        for qw( with_meta1 with_meta2 with_caller1 with_caller2 as_is1 );

    {
        my ( $caller, $arg1 ) = UseAllOptions::with_caller1(42);
        is( $caller, 'UseAllOptions', 'with_caller wrapped sub gets the right caller' );
        is( $arg1, 42, 'with_caller wrapped sub returns argument it was passed' );
    }

    {
        my ( $meta, $arg1 ) = UseAllOptions::with_meta1(42);
        isa_ok( $meta, 'Moose::Meta::Class', 'with_meta first argument' );
        is( $arg1, 42, 'with_meta1 returns argument it was passed' );
    }

    is(
        prototype( UseAllOptions->can('with_caller2') ),
        prototype( AllOptions->can('with_caller2') ),
        'using correct prototype on with_meta function'
    );

    is(
        prototype( UseAllOptions->can('with_meta2') ),
        prototype( AllOptions->can('with_meta2') ),
        'using correct prototype on with_meta function'
    );
}

{
    package UseAllOptions;
    AllOptions->unimport();
}

{
    ok( ! UseAllOptions->can($_), "UseAllOptions::$_ has been unimported" )
        for qw( with_meta1 with_meta2 with_caller1 with_caller2 as_is1 );
}

{
    package InitMetaError;
    use Moose::Exporter;
    use Moose ();
    Moose::Exporter->setup_import_methods(also => ['Moose']);
    sub init_meta {
        my $package = shift;
        my %options = @_;
        Moose->init_meta(%options, metaclass => 'Not::Loaded');
    }
}

{
    package InitMetaError::Role;
    use Moose::Exporter;
    use Moose::Role ();
    Moose::Exporter->setup_import_methods(also => ['Moose::Role']);
    sub init_meta {
        my $package = shift;
        my %options = @_;
        Moose::Role->init_meta(%options, metaclass => 'Not::Loaded');
    }
}

{
    package WantsInvalidMetaclass;
    ::like(
        ::exception { InitMetaError->import },
        qr/The Metaclass Not::Loaded must be loaded\. \(Perhaps you forgot to 'use Not::Loaded'\?\)/,
        "error when wanting a nonexistent metaclass"
    );
}

{
    package WantsInvalidMetaclass::Role;
    ::like(
        ::exception { InitMetaError::Role->import },
        qr/The Metaclass Not::Loaded must be loaded\. \(Perhaps you forgot to 'use Not::Loaded'\?\)/,
        "error when wanting a nonexistent metaclass"
    );
}

{
    my @init_metas_called;

    BEGIN {
        package MultiLevelExporter1;
        use Moose::Exporter;

        sub foo  { 1 }
        sub bar  { 1 }
        sub baz  { 1 }
        sub quux { 1 }

        Moose::Exporter->setup_import_methods(
            with_meta => [qw(foo bar baz quux)],
        );

        sub init_meta {
            push @init_metas_called, 1;
        }

        $INC{'MultiLevelExporter1.pm'} = __FILE__;
    }

    BEGIN {
        package MultiLevelExporter2;
        use Moose::Exporter;

        sub bar  { 2 }
        sub baz  { 2 }
        sub quux { 2 }

        Moose::Exporter->setup_import_methods(
            also      => ['MultiLevelExporter1'],
            with_meta => [qw(bar baz quux)],
        );

        sub init_meta {
            push @init_metas_called, 2;
        }

        $INC{'MultiLevelExporter2.pm'} = __FILE__;
    }

    BEGIN {
        package MultiLevelExporter3;
        use Moose::Exporter;

        sub baz  { 3 }
        sub quux { 3 }

        Moose::Exporter->setup_import_methods(
            also      => ['MultiLevelExporter2'],
            with_meta => [qw(baz quux)],
        );

        sub init_meta {
            push @init_metas_called, 3;
        }

        $INC{'MultiLevelExporter3.pm'} = __FILE__;
    }

    BEGIN {
        package MultiLevelExporter4;
        use Moose::Exporter;

        sub quux { 4 }

        Moose::Exporter->setup_import_methods(
            also      => ['MultiLevelExporter3'],
            with_meta => [qw(quux)],
        );

        sub init_meta {
            push @init_metas_called, 4;
        }

        $INC{'MultiLevelExporter4.pm'} = __FILE__;
    }

    BEGIN { @init_metas_called = () }
    {
        package UsesMulti1;
        use Moose;
        use MultiLevelExporter1;
        ::is(foo(), 1);
        ::is(bar(), 1);
        ::is(baz(), 1);
        ::is(quux(), 1);
    }
    use Data::Dumper;
    BEGIN { is_deeply(\@init_metas_called, [ 1 ]) || diag(Dumper(\@init_metas_called)) }

    BEGIN { @init_metas_called = () }
    {
        package UsesMulti2;
        use Moose;
        use MultiLevelExporter2;
        ::is(foo(), 1);
        ::is(bar(), 2);
        ::is(baz(), 2);
        ::is(quux(), 2);
    }
    BEGIN { is_deeply(\@init_metas_called, [ 2, 1 ]) || diag(Dumper(\@init_metas_called)) }

    BEGIN { @init_metas_called = () }
    {
        package UsesMulti3;
        use Moose;
        use MultiLevelExporter3;
        ::is(foo(), 1);
        ::is(bar(), 2);
        ::is(baz(), 3);
        ::is(quux(), 3);
    }
    BEGIN { is_deeply(\@init_metas_called, [ 3, 2, 1 ]) || diag(Dumper(\@init_metas_called)) }

    BEGIN { @init_metas_called = () }
    {
        package UsesMulti4;
        use Moose;
        use MultiLevelExporter4;
        ::is(foo(), 1);
        ::is(bar(), 2);
        ::is(baz(), 3);
        ::is(quux(), 4);
    }
    BEGIN { is_deeply(\@init_metas_called, [ 4, 3, 2, 1 ]) || diag(Dumper(\@init_metas_called)) }
}

# Using "also => [ 'MooseX::UsesAlsoMoose', 'MooseX::SomethingElse' ]" should
# continue to work. The init_meta order needs to be MooseX::CurrentExporter,
# MooseX::UsesAlsoMoose, Moose, MooseX::SomethingElse. This is a pretty ugly
# and messed up use case, but necessary until we come up with a better way to
# do it.

{
    my @init_metas_called;

    BEGIN {
        package AlsoTest::Role1;
        use Moose::Role;

        $INC{'AlsoTest/Role1.pm'} = __FILE__;
    }

    BEGIN {
        package AlsoTest1;
        use Moose::Exporter;

        Moose::Exporter->setup_import_methods(
            also => [ 'Moose' ],
        );

        sub init_meta {
            shift;
            my %opts = @_;
            ::ok(!Class::MOP::class_of($opts{for_class}));
            push @init_metas_called, 1;
        }

        $INC{'AlsoTest1.pm'} = __FILE__;
    }

    BEGIN {
        package AlsoTest2;
        use Moose::Exporter;
        use Moose::Util::MetaRole ();

        Moose::Exporter->setup_import_methods;

        sub init_meta {
            shift;
            my %opts = @_;
            ::ok(Class::MOP::class_of($opts{for_class}));
            Moose::Util::MetaRole::apply_metaroles(
                for => $opts{for_class},
                class_metaroles => {
                    class => ['AlsoTest::Role1'],
                },
            );
            push @init_metas_called, 2;
        }

        $INC{'AlsoTest2.pm'} = __FILE__;
    }

    BEGIN {
        package AlsoTest3;
        use Moose::Exporter;

        Moose::Exporter->setup_import_methods(
            also => [ 'AlsoTest1', 'AlsoTest2' ],
        );

        sub init_meta {
            shift;
            my %opts = @_;
            ::ok(!Class::MOP::class_of($opts{for_class}));
            push @init_metas_called, 3;
        }

        $INC{'AlsoTest3.pm'} = __FILE__;
    }

    BEGIN { @init_metas_called = () }
    {
        package UsesAlsoTest3;
        use AlsoTest3;
    }
    use Data::Dumper;
    BEGIN {
        is_deeply(\@init_metas_called, [ 3, 1, 2 ])
            || diag(Dumper(\@init_metas_called));
        isa_ok(Class::MOP::class_of('UsesAlsoTest3'), 'Moose::Meta::Class');
        does_ok(Class::MOP::class_of('UsesAlsoTest3'), 'AlsoTest::Role1');
    }

}

done_testing;
