use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{
    package Foo;
    use metaclass;
}

=pod

This is the same test as 080_meta_package.t just here
we call all the methods through Class::MOP::Class.

=cut

# ----------------------------------------------------------------------
## tests adding a HASH

ok(!defined($Foo::{foo}), '... the %foo slot has not been created yet');
ok(!Foo->meta->has_package_symbol('%foo'), '... the meta agrees');

is( exception {
    Foo->meta->add_package_symbol('%foo' => { one => 1 });
}, undef, '... created %Foo::foo successfully' );

# ... scalar should NOT be created here

ok(!Foo->meta->has_package_symbol('$foo'), '... SCALAR shouldnt have been created too');
ok(!Foo->meta->has_package_symbol('@foo'), '... ARRAY shouldnt have been created too');
ok(!Foo->meta->has_package_symbol('&foo'), '... CODE shouldnt have been created too');

ok(defined($Foo::{foo}), '... the %foo slot was created successfully');
ok(Foo->meta->has_package_symbol('%foo'), '... the meta agrees');

# check the value ...

{
    no strict 'refs';
    ok(exists ${'Foo::foo'}{one}, '... our %foo was initialized correctly');
    is(${'Foo::foo'}{one}, 1, '... our %foo was initialized correctly');
}

my $foo = Foo->meta->get_package_symbol('%foo');
is_deeply({ one => 1 }, $foo, '... got the right package variable back');

# ... make sure changes propogate up

$foo->{two} = 2;

{
    no strict 'refs';
    is(\%{'Foo::foo'}, Foo->meta->get_package_symbol('%foo'), '... our %foo is the same as the metas');

    ok(exists ${'Foo::foo'}{two}, '... our %foo was updated correctly');
    is(${'Foo::foo'}{two}, 2, '... our %foo was updated correctly');
}

# ----------------------------------------------------------------------
## test adding an ARRAY

ok(!defined($Foo::{bar}), '... the @bar slot has not been created yet');

is( exception {
    Foo->meta->add_package_symbol('@bar' => [ 1, 2, 3 ]);
}, undef, '... created @Foo::bar successfully' );

ok(defined($Foo::{bar}), '... the @bar slot was created successfully');
ok(Foo->meta->has_package_symbol('@bar'), '... the meta agrees');

# ... why does this not work ...

ok(!Foo->meta->has_package_symbol('$bar'), '... SCALAR shouldnt have been created too');
ok(!Foo->meta->has_package_symbol('%bar'), '... HASH shouldnt have been created too');
ok(!Foo->meta->has_package_symbol('&bar'), '... CODE shouldnt have been created too');

# check the value itself

{
    no strict 'refs';
    is(scalar @{'Foo::bar'}, 3, '... our @bar was initialized correctly');
    is(${'Foo::bar'}[1], 2, '... our @bar was initialized correctly');
}

# ----------------------------------------------------------------------
## test adding a SCALAR

ok(!defined($Foo::{baz}), '... the $baz slot has not been created yet');

is( exception {
    Foo->meta->add_package_symbol('$baz' => 10);
}, undef, '... created $Foo::baz successfully' );

ok(defined($Foo::{baz}), '... the $baz slot was created successfully');
ok(Foo->meta->has_package_symbol('$baz'), '... the meta agrees');

ok(!Foo->meta->has_package_symbol('@baz'), '... ARRAY shouldnt have been created too');
ok(!Foo->meta->has_package_symbol('%baz'), '... HASH shouldnt have been created too');
ok(!Foo->meta->has_package_symbol('&baz'), '... CODE shouldnt have been created too');

is(${Foo->meta->get_package_symbol('$baz')}, 10, '... got the right value back');

{
    no strict 'refs';
    ${'Foo::baz'} = 1;

    is(${'Foo::baz'}, 1, '... our $baz was assigned to correctly');
    is(${Foo->meta->get_package_symbol('$baz')}, 1, '... the meta agrees');
}

# ----------------------------------------------------------------------
## test adding a CODE

ok(!defined($Foo::{funk}), '... the &funk slot has not been created yet');

is( exception {
    Foo->meta->add_package_symbol('&funk' => sub { "Foo::funk" });
}, undef, '... created &Foo::funk successfully' );

ok(defined($Foo::{funk}), '... the &funk slot was created successfully');
ok(Foo->meta->has_package_symbol('&funk'), '... the meta agrees');

ok(!Foo->meta->has_package_symbol('$funk'), '... SCALAR shouldnt have been created too');
ok(!Foo->meta->has_package_symbol('@funk'), '... ARRAY shouldnt have been created too');
ok(!Foo->meta->has_package_symbol('%funk'), '... HASH shouldnt have been created too');

{
    no strict 'refs';
    ok(defined &{'Foo::funk'}, '... our &funk exists');
}

is(Foo->funk(), 'Foo::funk', '... got the right value from the function');

# ----------------------------------------------------------------------
## test multiple slots in the glob

my $ARRAY = [ 1, 2, 3 ];
my $CODE = sub { "Foo::foo" };

is( exception {
    Foo->meta->add_package_symbol('@foo' => $ARRAY);
}, undef, '... created @Foo::foo successfully' );

ok(Foo->meta->has_package_symbol('@foo'), '... the @foo slot was added successfully');
is(Foo->meta->get_package_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');

is( exception {
    Foo->meta->add_package_symbol('&foo' => $CODE);
}, undef, '... created &Foo::foo successfully' );

ok(Foo->meta->has_package_symbol('&foo'), '... the meta agrees');
is(Foo->meta->get_package_symbol('&foo'), $CODE, '... got the right value for &Foo::foo');

is( exception {
    Foo->meta->add_package_symbol('$foo' => 'Foo::foo');
}, undef, '... created $Foo::foo successfully' );

ok(Foo->meta->has_package_symbol('$foo'), '... the meta agrees');
my $SCALAR = Foo->meta->get_package_symbol('$foo');
is($$SCALAR, 'Foo::foo', '... got the right scalar value back');

{
    no strict 'refs';
    is(${'Foo::foo'}, 'Foo::foo', '... got the right value from the scalar');
}

is( exception {
    Foo->meta->remove_package_symbol('%foo');
}, undef, '... removed %Foo::foo successfully' );

ok(!Foo->meta->has_package_symbol('%foo'), '... the %foo slot was removed successfully');
ok(Foo->meta->has_package_symbol('@foo'), '... the @foo slot still exists');
ok(Foo->meta->has_package_symbol('&foo'), '... the &foo slot still exists');
ok(Foo->meta->has_package_symbol('$foo'), '... the $foo slot still exists');

is(Foo->meta->get_package_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');
is(Foo->meta->get_package_symbol('&foo'), $CODE, '... got the right value for &Foo::foo');
is(Foo->meta->get_package_symbol('$foo'), $SCALAR, '... got the right value for $Foo::foo');

{
    no strict 'refs';
    ok(!defined(*{"Foo::foo"}{HASH}), '... the %foo slot has been removed successfully');
    ok(defined(*{"Foo::foo"}{ARRAY}), '... the @foo slot has NOT been removed');
    ok(defined(*{"Foo::foo"}{CODE}), '... the &foo slot has NOT been removed');
    ok(defined(${"Foo::foo"}), '... the $foo slot has NOT been removed');
}

is( exception {
    Foo->meta->remove_package_symbol('&foo');
}, undef, '... removed &Foo::foo successfully' );

ok(!Foo->meta->has_package_symbol('&foo'), '... the &foo slot no longer exists');

ok(Foo->meta->has_package_symbol('@foo'), '... the @foo slot still exists');
ok(Foo->meta->has_package_symbol('$foo'), '... the $foo slot still exists');

is(Foo->meta->get_package_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');
is(Foo->meta->get_package_symbol('$foo'), $SCALAR, '... got the right value for $Foo::foo');

{
    no strict 'refs';
    ok(!defined(*{"Foo::foo"}{HASH}), '... the %foo slot has been removed successfully');
    ok(!defined(*{"Foo::foo"}{CODE}), '... the &foo slot has now been removed');
    ok(defined(*{"Foo::foo"}{ARRAY}), '... the @foo slot has NOT been removed');
    ok(defined(${"Foo::foo"}), '... the $foo slot has NOT been removed');
}

is( exception {
    Foo->meta->remove_package_symbol('$foo');
}, undef, '... removed $Foo::foo successfully' );

ok(!Foo->meta->has_package_symbol('$foo'), '... the $foo slot no longer exists');

ok(Foo->meta->has_package_symbol('@foo'), '... the @foo slot still exists');

is(Foo->meta->get_package_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');

{
    no strict 'refs';
    ok(!defined(*{"Foo::foo"}{HASH}), '... the %foo slot has been removed successfully');
    ok(!defined(*{"Foo::foo"}{CODE}), '... the &foo slot has now been removed');
    ok(!defined(${"Foo::foo"}), '... the $foo slot has now been removed');
    ok(defined(*{"Foo::foo"}{ARRAY}), '... the @foo slot has NOT been removed');
}

done_testing;
