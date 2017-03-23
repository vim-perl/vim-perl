use strict;
use warnings;

use Test::More;

use Class::MOP;
use Class::MOP::Class;

=pod

  A
 / \
B   C
 \ /
  D

=cut

{
    package My::A;
    use metaclass;
    package My::B;
    our @ISA = ('My::A');
    package My::C;
    our @ISA = ('My::A');
    package My::D;
    our @ISA = ('My::B', 'My::C');
}

is_deeply(
    [ My::D->meta->class_precedence_list ],
    [ 'My::D', 'My::B', 'My::A', 'My::C', 'My::A' ],
    '... My::D->meta->class_precedence_list == (D B A C A)');

is_deeply(
    [ My::D->meta->linearized_isa ],
    [ 'My::D', 'My::B', 'My::A', 'My::C' ],
    '... My::D->meta->linearized_isa == (D B A C)');

=pod

 A <-+
 |   |
 B   |
 |   |
 C --+

=cut

# 5.9.5+ dies at the moment of
# recursive @ISA definition, not later when
# you try to use the @ISAs.
eval {
    {
        package My::2::A;
        use metaclass;
        our @ISA = ('My::2::C');

        package My::2::B;
        our @ISA = ('My::2::A');

        package My::2::C;
        our @ISA = ('My::2::B');
    }

    My::2::B->meta->class_precedence_list
};
ok($@, '... recursive inheritance breaks correctly :)');

=pod

 +--------+
 |    A   |
 |   / \  |
 +->B   C-+
     \ /
      D

=cut

{
    package My::3::A;
    use metaclass;
    package My::3::B;
    our @ISA = ('My::3::A');
    package My::3::C;
    our @ISA = ('My::3::A', 'My::3::B');
    package My::3::D;
    our @ISA = ('My::3::B', 'My::3::C');
}

is_deeply(
    [ My::3::D->meta->class_precedence_list ],
    [ 'My::3::D', 'My::3::B', 'My::3::A', 'My::3::C', 'My::3::A', 'My::3::B', 'My::3::A' ],
    '... My::3::D->meta->class_precedence_list == (D B A C A B A)');

is_deeply(
    [ My::3::D->meta->linearized_isa ],
    [ 'My::3::D', 'My::3::B', 'My::3::A', 'My::3::C' ],
    '... My::3::D->meta->linearized_isa == (D B A C B)');

=pod

Test all the class_precedence_lists
using Perl's own dispatcher to check
against.

=cut

my @CLASS_PRECEDENCE_LIST;

{
    package Foo;
    use metaclass;

    sub CPL { push @CLASS_PRECEDENCE_LIST => 'Foo' }

    package Bar;
    our @ISA = ('Foo');

    sub CPL {
        push @CLASS_PRECEDENCE_LIST => 'Bar';
        $_[0]->SUPER::CPL();
    }

    package Baz;
    use metaclass;
    our @ISA = ('Bar');

    sub CPL {
        push @CLASS_PRECEDENCE_LIST => 'Baz';
        $_[0]->SUPER::CPL();
    }

    package Foo::Bar;
    our @ISA = ('Baz');

    sub CPL {
        push @CLASS_PRECEDENCE_LIST => 'Foo::Bar';
        $_[0]->SUPER::CPL();
    }

    package Foo::Bar::Baz;
    our @ISA = ('Foo::Bar');

    sub CPL {
        push @CLASS_PRECEDENCE_LIST => 'Foo::Bar::Baz';
        $_[0]->SUPER::CPL();
    }

}

Foo::Bar::Baz->CPL();

is_deeply(
    [ Foo::Bar::Baz->meta->class_precedence_list ],
    [ @CLASS_PRECEDENCE_LIST ],
    '... Foo::Bar::Baz->meta->class_precedence_list == @CLASS_PRECEDENCE_LIST');

done_testing;
