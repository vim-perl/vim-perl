#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo::Base::Meta::Trait;
    use Moose::Role;
}

{
    package Foo::Base;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => { constructor => ['Foo::Base::Meta::Trait'] },
    );
    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::Meta::Trait;
    use Moose::Role;
}

{
    package Foo;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => { constructor => ['Foo::Meta::Trait'] }
    );
    ::ok(!Foo->meta->is_immutable);
    extends 'Foo::Base';
    ::ok(!Foo->meta->is_immutable);
}

done_testing;
