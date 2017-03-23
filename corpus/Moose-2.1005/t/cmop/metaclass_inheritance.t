use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

=pod

Test that a default set up will cause metaclasses to inherit
the same metaclass type, but produce different metaclasses.

=cut

{
    package Foo;
    use metaclass;

    package Bar;
    use base 'Foo';

    package Baz;
    use base 'Bar';
}

my $foo_meta = Foo->meta;
isa_ok($foo_meta, 'Class::MOP::Class');

is($foo_meta->name, 'Foo', '... foo_meta->name == Foo');

my $bar_meta = Bar->meta;
isa_ok($bar_meta, 'Class::MOP::Class');

is($bar_meta->name, 'Bar', '... bar_meta->name == Bar');
isnt($bar_meta, $foo_meta, '... Bar->meta != Foo->meta');

my $baz_meta = Baz->meta;
isa_ok($baz_meta, 'Class::MOP::Class');

is($baz_meta->name, 'Baz', '... baz_meta->name == Baz');
isnt($baz_meta, $bar_meta, '... Baz->meta != Bar->meta');
isnt($baz_meta, $foo_meta, '... Baz->meta != Foo->meta');

done_testing;
