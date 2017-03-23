#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Class::MOP;

{
    can_ok('Class::MOP::Class', 'meta');
    isa_ok(Class::MOP::Class->meta->find_method_by_name('meta'),
           'Class::MOP::Method::Meta');

    {
        package Baz;
        use metaclass;
    }
    can_ok('Baz', 'meta');
    isa_ok(Baz->meta->find_method_by_name('meta'),
           'Class::MOP::Method::Meta');

    my $meta = Class::MOP::Class->create('Quux');
    can_ok('Quux', 'meta');
    isa_ok(Quux->meta->find_method_by_name('meta'),
           'Class::MOP::Method::Meta');
}

{
    {
        package Blarg;
        use metaclass meta_name => 'blarg';
    }
    ok(!Blarg->can('meta'));
    can_ok('Blarg', 'blarg');
    isa_ok(Blarg->blarg->find_method_by_name('blarg'),
           'Class::MOP::Method::Meta');

    my $meta = Class::MOP::Class->create('Blorg', meta_name => 'blorg');
    ok(!Blorg->can('meta'));
    can_ok('Blorg', 'blorg');
    isa_ok(Blorg->blorg->find_method_by_name('blorg'),
           'Class::MOP::Method::Meta');
}

{
    {
        package Foo;
        use metaclass meta_name => undef;
    }

    my $meta = Class::MOP::class_of('Foo');
    ok(!$meta->has_method('meta'), "no meta method was installed");
    $meta->add_method(meta => sub { die 'META' });
    is( exception { $meta->find_method_by_name('meta') }, undef, "can do meta-level stuff" );
    is( exception { $meta->make_immutable }, undef, "can do meta-level stuff" );
    is( exception { $meta->class_precedence_list }, undef, "can do meta-level stuff" );
}

{
    my $meta = Class::MOP::Class->create('Bar', meta_name => undef);
    ok(!$meta->has_method('meta'), "no meta method was installed");
    $meta->add_method(meta => sub { die 'META' });
    is( exception { $meta->find_method_by_name('meta') }, undef, "can do meta-level stuff" );
    is( exception { $meta->make_immutable }, undef, "can do meta-level stuff" );
    is( exception { $meta->class_precedence_list }, undef, "can do meta-level stuff" );
}

done_testing;
