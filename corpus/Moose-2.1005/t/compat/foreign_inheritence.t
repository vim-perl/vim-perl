#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;


{

    package Elk;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        bless { no_moose => "Elk" } => $class;
    }

    sub no_moose { $_[0]->{no_moose} }

    package Foo::Moose;
    use Moose;

    extends 'Elk';

    has 'moose' => ( is => 'ro', default => 'Foo' );

    sub new {
        my $class = shift;
        my $super = $class->SUPER::new(@_);
        return $class->meta->new_object( '__INSTANCE__' => $super, @_ );
    }

    __PACKAGE__->meta->make_immutable( inline_constructor => 0, debug => 0 );

    package Bucket;
    use metaclass 'Class::MOP::Class';

    __PACKAGE__->meta->add_attribute(
        'squeegee' => ( accessor => 'squeegee' ) );

    package Old::Bucket::Nose;

    # see http://www.moosefoundation.org/moose_facts.htm
    use Moose;

    extends 'Bucket';

    package MyBase;
    sub foo { }

    package Custom::Meta1;
    use base qw(Moose::Meta::Class);

    package Custom::Meta2;
    use base qw(Moose::Meta::Class);

    package SubClass1;
    use metaclass 'Custom::Meta1';
    use Moose;

    extends 'MyBase';

    package SubClass2;
    use metaclass 'Custom::Meta2';
    use Moose;

    # XXX FIXME subclassing meta-attrs and immutable-ing the subclass fails
}

my $foo_moose = Foo::Moose->new();
isa_ok( $foo_moose, 'Foo::Moose' );
isa_ok( $foo_moose, 'Elk' );

is( $foo_moose->no_moose, 'Elk',
    '... got the right value from the Elk method' );
is( $foo_moose->moose, 'Foo',
    '... got the right value from the Foo::Moose method' );

is( exception {
    Old::Bucket::Nose->meta->make_immutable( debug => 0 );
}, undef, 'Immutability on Moose class extending Class::MOP class ok' );

is( exception {
    SubClass2->meta->superclasses('MyBase');
}, undef, 'Can subclass the same non-Moose class twice with different metaclasses' );

done_testing;
