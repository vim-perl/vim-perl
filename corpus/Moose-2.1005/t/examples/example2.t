#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

sub U {
    my $f = shift;
    sub { $f->($f, @_) };
}

sub Y {
    my $f = shift;
    U(sub { my $h = shift; sub { $f->(U($h)->())->(@_) } })->();
}

{
    package List;
    use Moose::Role;

    has '_list' => (
        is       => 'ro',
        isa      => 'ArrayRef',
        init_arg => '::',
        default  => sub { [] }
    );

    sub head { (shift)->_list->[0] }
    sub tail {
        my $self = shift;
        (ref $self)->new(
            '::' => [
                @{$self->_list}[1 .. $#{$self->_list}]
            ]
        );
    }

    sub print {
        join ", " => @{$_[0]->_list};
    }

    package List::Immutable;
    use Moose::Role;

    requires 'head';
    requires 'tail';

    sub is_empty { not defined ($_[0]->head) }

    sub length {
        my $self = shift;
        (::Y(sub {
            my $redo = shift;
            sub {
                my ($list, $acc) = @_;
                return $acc if $list->is_empty;
                $redo->($list->tail, $acc + 1);
            }
        }))->($self, 0);
    }

    sub apply {
        my ($self, $function) = @_;
        (::Y(sub {
            my $redo = shift;
            sub {
                my ($list, $func, $acc) = @_;
                return (ref $list)->new('::' => $acc)
                    if $list->is_empty;
                $redo->(
                    $list->tail,
                    $func,
                    [ @{$acc}, $func->($list->head) ]
                );
            }
        }))->($self, $function, []);
    }

    package My::List1;
    use Moose;

    ::is( ::exception {
        with 'List', 'List::Immutable';
    }, undef, '... successfully composed roles together' );

    package My::List2;
    use Moose;

    ::is( ::exception {
        with 'List::Immutable', 'List';
    }, undef, '... successfully composed roles together' );

}

{
    my $coll = My::List1->new;
    isa_ok($coll, 'My::List1');

    ok($coll->does('List'), '... $coll does List');
    ok($coll->does('List::Immutable'), '... $coll does List::Immutable');

    ok($coll->is_empty, '... we have an empty collection');
    is($coll->length, 0, '... we have a length of 1 for the collection');
}

{
    my $coll = My::List2->new;
    isa_ok($coll, 'My::List2');

    ok($coll->does('List'), '... $coll does List');
    ok($coll->does('List::Immutable'), '... $coll does List::Immutable');

    ok($coll->is_empty, '... we have an empty collection');
    is($coll->length, 0, '... we have a length of 1 for the collection');
}

{
    my $coll = My::List1->new('::' => [ 1 .. 10 ]);
    isa_ok($coll, 'My::List1');

    ok($coll->does('List'), '... $coll does List');
    ok($coll->does('List::Immutable'), '... $coll does List::Immutable');

    ok(!$coll->is_empty, '... we do not have an empty collection');
    is($coll->length, 10, '... we have a length of 10 for the collection');

    is($coll->print, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', '... got the right printed value');

    my $coll2 = $coll->apply(sub { $_[0] * $_[0] });
    isa_ok($coll2, 'My::List1');

    is($coll->print, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', '... original is still the same');
    is($coll2->print, '1, 4, 9, 16, 25, 36, 49, 64, 81, 100', '... new collection is changed');
}

{
    my $coll = My::List2->new('::' => [ 1 .. 10 ]);
    isa_ok($coll, 'My::List2');

    ok($coll->does('List'), '... $coll does List');
    ok($coll->does('List::Immutable'), '... $coll does List::Immutable');

    ok(!$coll->is_empty, '... we do not have an empty collection');
    is($coll->length, 10, '... we have a length of 10 for the collection');

    is($coll->print, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', '... got the right printed value');

    my $coll2 = $coll->apply(sub { $_[0] * $_[0] });
    isa_ok($coll2, 'My::List2');

    is($coll->print, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', '... original is still the same');
    is($coll2->print, '1, 4, 9, 16, 25, 36, 49, 64, 81, 100', '... new collection is changed');
}

done_testing;
