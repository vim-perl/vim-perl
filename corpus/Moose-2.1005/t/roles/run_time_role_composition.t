#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Scalar::Util qw(blessed);


=pod

This test can be used as a basis for the runtime role composition.
Apparently it is not as simple as just making an anon class. One of
the problems is the way that anon classes are DESTROY-ed, which is
not very compatible with how instances are dealt with.

=cut

{
    package Bark;
    use Moose::Role;

    sub talk { 'woof' }

    package Sleeper;
    use Moose::Role;

    sub sleep { 'snore' }
    sub talk { 'zzz' }

    package My::Class;
    use Moose;

    sub sleep { 'nite-nite' }
}

my $obj = My::Class->new;
isa_ok($obj, 'My::Class');

my $obj2 = My::Class->new;
isa_ok($obj2, 'My::Class');

{
    ok(!$obj->can( 'talk' ), "... the role is not composed yet");

    ok(!$obj->does('Bark'), '... we do not do any roles yet');

    Bark->meta->apply($obj);

    ok($obj->does('Bark'), '... we now do the Bark role');
    ok(!My::Class->does('Bark'), '... the class does not do the Bark role');

    isa_ok($obj, 'My::Class');
    isnt(blessed($obj), 'My::Class', '... but it is no longer blessed into My::Class');

    ok(!My::Class->can('talk'), "... the role is not composed at the class level");
    ok($obj->can('talk'), "... the role is now composed at the object level");

    is($obj->talk, 'woof', '... got the right return value for the newly composed method');
}

{
    ok(!$obj2->does('Sleeper'), '... we do not do any roles yet');

    Sleeper->meta->apply($obj2);

    ok($obj2->does('Sleeper'), '... we now do the Sleeper role');
    isnt(blessed($obj), blessed($obj2), '... they DO NOT share the same anon-class/role thing');
}

{
    is($obj->sleep, 'nite-nite', '... the original method responds as expected');

    ok(!$obj->does('Sleeper'), '... we do not do the Sleeper role');

    Sleeper->meta->apply($obj);

    ok($obj->does('Bark'), '... we still do the Bark role');
    ok($obj->does('Sleeper'), '... we now do the Sleeper role too');

    ok(!My::Class->does('Sleeper'), '... the class does not do the Sleeper role');

    isnt(blessed($obj), blessed($obj2), '... they still don\'t share the same anon-class/role thing');

    isa_ok($obj, 'My::Class');

    is(My::Class->sleep, 'nite-nite', '... the original method still responds as expected');

    is($obj->sleep, 'snore', '... got the right return value for the newly composed method');
    is($obj->talk, 'zzz', '... got the right return value for the newly composed method');
}

{
    ok(!$obj2->does('Bark'), '... we do not do Bark yet');

    Bark->meta->apply($obj2);

    ok($obj2->does('Bark'), '... we now do the Bark role');
    isnt(blessed($obj), blessed($obj2), '... they still don\'t share the same anon-class/role thing');
}

# test that anon classes are equivalent after role composition in the same order
{
    foreach ($obj, $obj2) {
        $_ = My::Class->new;
        Bark->meta->apply($_);
        Sleeper->meta->apply($_);
    }
    is(blessed($obj), blessed($obj2), '... they now share the same anon-class/role thing');
}

done_testing;
