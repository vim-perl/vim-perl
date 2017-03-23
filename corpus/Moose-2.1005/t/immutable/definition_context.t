#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    use Moose::Util::TypeConstraints;
    use Carp 'confess';
    subtype 'Death', as 'Int', where { $_ == 1 };
    coerce  'Death', from 'Any', via { confess };
}

{
    my ($attr_foo_line, $attr_bar_line, $ctor_line);
    {
        package Foo;
        use Moose;

        has foo => (
            is     => 'rw',
            isa    => 'Death',
            coerce => 1,
        );
        $attr_foo_line = __LINE__ - 5;

        has bar => (
            accessor => 'baz',
            isa      => 'Death',
            coerce   => 1,
        );
        $attr_bar_line = __LINE__ - 5;

        __PACKAGE__->meta->make_immutable;
        $ctor_line = __LINE__ - 1;
    }

    like(
        exception { Foo->new(foo => 2) },
        qr/called at constructor Foo::new \(defined at $0 line $ctor_line\)/,
        "got definition context for the constructor"
    );

    like(
        exception { my $f = Foo->new(foo => 1); $f->foo(2) },
        qr/called at accessor Foo::foo \(defined at $0 line $attr_foo_line\)/,
        "got definition context for the accessor"
    );

    like(
        exception { my $f = Foo->new(foo => 1); $f->baz(2) },
        qr/called at accessor Foo::baz of attribute bar \(defined at $0 line $attr_bar_line\)/,
        "got definition context for the accessor"
    );
}

{
    my ($dtor_line);
    {
        package Bar;
        use Moose;

        # just dying here won't work, because perl's exception handling is
        # terrible
        sub DEMOLISH { try { confess } catch { warn $_ } }

        __PACKAGE__->meta->make_immutable;
        $dtor_line = __LINE__ - 1;
    }

    {
        my $warning = '';
        local $SIG{__WARN__} = sub { $warning .= $_[0] };
        { Bar->new }
        like(
            $warning,
            qr/called at destructor Bar::DESTROY \(defined at $0 line $dtor_line\)/,
            "got definition context for the destructor"
        );
    }
}

done_testing;
