#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo::Meta::Constructor1;
    use Moose::Role;
}

{
    package Foo::Meta::Constructor2;
    use Moose::Role;
}

{
    package Foo;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => { constructor => ['Foo::Meta::Constructor1'] },
    );
}

{
    package Foo::Sub;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => { constructor => ['Foo::Meta::Constructor2'] },
    );
    extends 'Foo';
}

{
    package Foo::Sub::Sub;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => { constructor => ['Foo::Meta::Constructor2'] },
    );
    ::is( ::exception { extends 'Foo::Sub' }, undef, "doesn't try to fix if nothing is needed" );
}

done_testing;
