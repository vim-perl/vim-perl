use strict;
use warnings;

use Test::More;
use File::Spec;
use Scalar::Util 'reftype';

BEGIN {use Class::MOP;
    require_ok(File::Spec->catfile('examples', 'InsideOutClass.pod'));
}

{
    package Foo;

    use strict;
    use warnings;

    use metaclass (
        'attribute_metaclass' => 'InsideOutClass::Attribute',
        'instance_metaclass'  => 'InsideOutClass::Instance'
    );

    Foo->meta->add_attribute('foo' => (
        accessor  => 'foo',
        predicate => 'has_foo',
    ));

    Foo->meta->add_attribute('bar' => (
        reader  => 'get_bar',
        writer  => 'set_bar',
        default => 'FOO is BAR'
    ));

    sub new  {
        my $class = shift;
        $class->meta->new_object(@_);
    }

    package Bar;
    use metaclass (
        'attribute_metaclass' => 'InsideOutClass::Attribute',
        'instance_metaclass'  => 'InsideOutClass::Instance'
    );

    use strict;
    use warnings;

    use base 'Foo';

    Bar->meta->add_attribute('baz' => (
        accessor  => 'baz',
        predicate => 'has_baz',
    ));

    package Baz;

    use strict;
    use warnings;
    use metaclass (
        'attribute_metaclass' => 'InsideOutClass::Attribute',
        'instance_metaclass'  => 'InsideOutClass::Instance'
    );

    Baz->meta->add_attribute('bling' => (
        accessor  => 'bling',
        default   => 'Baz::bling'
    ));

    package Bar::Baz;
    use metaclass (
        'attribute_metaclass' => 'InsideOutClass::Attribute',
        'instance_metaclass'  => 'InsideOutClass::Instance'
    );

    use strict;
    use warnings;

    use base 'Bar', 'Baz';
}

my $foo = Foo->new();
isa_ok($foo, 'Foo');

is(reftype($foo), 'SCALAR', '... Foo is made with SCALAR');

can_ok($foo, 'foo');
can_ok($foo, 'has_foo');
can_ok($foo, 'get_bar');
can_ok($foo, 'set_bar');

ok(!$foo->has_foo, '... Foo::foo is not defined yet');
is($foo->foo(), undef, '... Foo::foo is not defined yet');
is($foo->get_bar(), 'FOO is BAR', '... Foo::bar has been initialized');

$foo->foo('This is Foo');

ok($foo->has_foo, '... Foo::foo is defined now');
is($foo->foo(), 'This is Foo', '... Foo::foo == "This is Foo"');

$foo->set_bar(42);
is($foo->get_bar(), 42, '... Foo::bar == 42');

my $foo2 = Foo->new();
isa_ok($foo2, 'Foo');

is(reftype($foo2), 'SCALAR', '... Foo is made with SCALAR');

ok(!$foo2->has_foo, '... Foo2::foo is not defined yet');
is($foo2->foo(), undef, '... Foo2::foo is not defined yet');
is($foo2->get_bar(), 'FOO is BAR', '... Foo2::bar has been initialized');

$foo2->set_bar('DONT PANIC');
is($foo2->get_bar(), 'DONT PANIC', '... Foo2::bar == DONT PANIC');

is($foo->get_bar(), 42, '... Foo::bar == 42');

# now Bar ...

my $bar = Bar->new();
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

is(reftype($bar), 'SCALAR', '... Bar is made with SCALAR');

can_ok($bar, 'foo');
can_ok($bar, 'has_foo');
can_ok($bar, 'get_bar');
can_ok($bar, 'set_bar');
can_ok($bar, 'baz');
can_ok($bar, 'has_baz');

ok(!$bar->has_foo, '... Bar::foo is not defined yet');
is($bar->foo(), undef, '... Bar::foo is not defined yet');
is($bar->get_bar(), 'FOO is BAR', '... Bar::bar has been initialized');
ok(!$bar->has_baz, '... Bar::baz is not defined yet');
is($bar->baz(), undef, '... Bar::baz is not defined yet');

$bar->foo('This is Bar::foo');

ok($bar->has_foo, '... Bar::foo is defined now');
is($bar->foo(), 'This is Bar::foo', '... Bar::foo == "This is Bar"');
is($bar->get_bar(), 'FOO is BAR', '... Bar::bar has been initialized');

$bar->baz('This is Bar::baz');

ok($bar->has_baz, '... Bar::baz is defined now');
is($bar->baz(), 'This is Bar::baz', '... Bar::foo == "This is Bar"');
is($bar->foo(), 'This is Bar::foo', '... Bar::foo == "This is Bar"');
is($bar->get_bar(), 'FOO is BAR', '... Bar::bar has been initialized');

# now Baz ...

my $baz = Bar::Baz->new();
isa_ok($baz, 'Bar::Baz');
isa_ok($baz, 'Bar');
isa_ok($baz, 'Foo');
isa_ok($baz, 'Baz');

is(reftype($baz), 'SCALAR', '... Bar::Baz is made with SCALAR');

can_ok($baz, 'foo');
can_ok($baz, 'has_foo');
can_ok($baz, 'get_bar');
can_ok($baz, 'set_bar');
can_ok($baz, 'baz');
can_ok($baz, 'has_baz');
can_ok($baz, 'bling');

is($baz->get_bar(), 'FOO is BAR', '... Bar::Baz::bar has been initialized');
is($baz->bling(), 'Baz::bling', '... Bar::Baz::bling has been initialized');

ok(!$baz->has_foo, '... Bar::Baz::foo is not defined yet');
is($baz->foo(), undef, '... Bar::Baz::foo is not defined yet');
ok(!$baz->has_baz, '... Bar::Baz::baz is not defined yet');
is($baz->baz(), undef, '... Bar::Baz::baz is not defined yet');

$baz->foo('This is Bar::Baz::foo');

ok($baz->has_foo, '... Bar::Baz::foo is defined now');
is($baz->foo(), 'This is Bar::Baz::foo', '... Bar::Baz::foo == "This is Bar"');
is($baz->get_bar(), 'FOO is BAR', '... Bar::Baz::bar has been initialized');
is($baz->bling(), 'Baz::bling', '... Bar::Baz::bling has been initialized');

$baz->baz('This is Bar::Baz::baz');

ok($baz->has_baz, '... Bar::Baz::baz is defined now');
is($baz->baz(), 'This is Bar::Baz::baz', '... Bar::Baz::foo == "This is Bar"');
is($baz->foo(), 'This is Bar::Baz::foo', '... Bar::Baz::foo == "This is Bar"');
is($baz->get_bar(), 'FOO is BAR', '... Bar::Baz::bar has been initialized');
is($baz->bling(), 'Baz::bling', '... Bar::Baz::bling has been initialized');

{
    no strict 'refs';

    ok(*{'Foo::foo'}{HASH}, '... there is a foo package variable in Foo');
    ok(*{'Foo::bar'}{HASH}, '... there is a bar package variable in Foo');

    is(scalar(keys(%{'Foo::foo'})), 4, '... got the right number of entries for Foo::foo');
    is(scalar(keys(%{'Foo::bar'})), 4, '... got the right number of entries for Foo::bar');

    ok(!*{'Bar::foo'}{HASH}, '... no foo package variable in Bar');
    ok(!*{'Bar::bar'}{HASH}, '... no bar package variable in Bar');
    ok(*{'Bar::baz'}{HASH}, '... there is a baz package variable in Bar');

    is(scalar(keys(%{'Bar::foo'})), 0, '... got the right number of entries for Bar::foo');
    is(scalar(keys(%{'Bar::bar'})), 0, '... got the right number of entries for Bar::bar');
    is(scalar(keys(%{'Bar::baz'})), 2, '... got the right number of entries for Bar::baz');

    ok(*{'Baz::bling'}{HASH}, '... there is a bar package variable in Baz');

    is(scalar(keys(%{'Baz::bling'})), 1, '... got the right number of entries for Baz::bling');

    ok(!*{'Bar::Baz::foo'}{HASH}, '... no foo package variable in Bar::Baz');
    ok(!*{'Bar::Baz::bar'}{HASH}, '... no bar package variable in Bar::Baz');
    ok(!*{'Bar::Baz::baz'}{HASH}, '... no baz package variable in Bar::Baz');
    ok(!*{'Bar::Baz::bling'}{HASH}, '... no bar package variable in Baz::Baz');

    is(scalar(keys(%{'Bar::Baz::foo'})), 0, '... got the right number of entries for Bar::Baz::foo');
    is(scalar(keys(%{'Bar::Baz::bar'})), 0, '... got the right number of entries for Bar::Baz::bar');
    is(scalar(keys(%{'Bar::Baz::baz'})), 0, '... got the right number of entries for Bar::Baz::baz');
    is(scalar(keys(%{'Bar::Baz::bling'})), 0, '... got the right number of entries for Bar::Baz::bling');
}

done_testing;
