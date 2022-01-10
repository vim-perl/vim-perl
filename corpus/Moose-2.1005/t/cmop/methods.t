use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Scalar::Util qw/reftype/;
use Sub::Name;

use Class::MOP;
use Class::MOP::Class;
use Class::MOP::Method;

{
    # This package tries to test &has_method as exhaustively as
    # possible. More corner cases are welcome :)
    package Foo;

    # import a sub
    use Scalar::Util 'blessed';

    sub pie;
    sub cake ();

    use constant FOO_CONSTANT => 'Foo-CONSTANT';

    # define a sub in package
    sub bar {'Foo::bar'}
    *baz = \&bar;

    # create something with the typeglob inside the package
    *baaz = sub {'Foo::baaz'};

    {    # method named with Sub::Name inside the package scope
        no strict 'refs';
        *{'Foo::floob'} = Sub::Name::subname 'floob' => sub {'!floob!'};
    }

    # We hateses the "used only once" warnings
    {
        my $temp1 = \&Foo::baz;
        my $temp2 = \&Foo::baaz;
    }

    package OinkyBoinky;
    our @ISA = "Foo";

    sub elk {'OinkyBoinky::elk'}

    package main;

    sub Foo::blah { $_[0]->Foo::baz() }

    {
        no strict 'refs';
        *{'Foo::bling'} = sub {'$$Bling$$'};
        *{'Foo::bang'} = Sub::Name::subname 'Foo::bang' => sub {'!BANG!'};
        *{'Foo::boom'} = Sub::Name::subname 'boom'      => sub {'!BOOM!'};

        eval "package Foo; sub evaled_foo { 'Foo::evaled_foo' }";
    }
}

my $Foo = Class::MOP::Class->initialize('Foo');

is join(' ', sort $Foo->get_method_list),
    'FOO_CONSTANT baaz bang bar baz blah cake evaled_foo floob pie';

ok( $Foo->has_method('pie'),  '... got the method stub pie' );
ok( $Foo->has_method('cake'), '... got the constant method stub cake' );

my $foo = sub {'Foo::foo'};

ok( !UNIVERSAL::isa( $foo, 'Class::MOP::Method' ),
    '... our method is not yet blessed' );

is( exception {
    $Foo->add_method( 'foo' => $foo );
}, undef, '... we added the method successfully' );

my $foo_method = $Foo->get_method('foo');

isa_ok( $foo_method, 'Class::MOP::Method' );

is( $foo_method->name, 'foo', '... got the right name for the method' );
is( $foo_method->package_name, 'Foo',
    '... got the right package name for the method' );

ok( $Foo->has_method('foo'),
    '... Foo->has_method(foo) (defined with Sub::Name)' );

is( $Foo->get_method('foo')->body, $foo,
    '... Foo->get_method(foo) == \&foo' );
is( $Foo->get_method('foo')->execute, 'Foo::foo',
    '... _method_foo->execute returns "Foo::foo"' );
is( Foo->foo(), 'Foo::foo', '... Foo->foo() returns "Foo::foo"' );

my $bork_blessed = bless sub { }, 'Non::Meta::Class';

is( exception {
  $Foo->add_method('bork', $bork_blessed);
}, undef, 'can add blessed sub as method');

# now check all our other items ...

ok( $Foo->has_method('FOO_CONSTANT'),
    '... not Foo->has_method(FOO_CONSTANT) (defined w/ use constant)' );
ok( !$Foo->has_method('bling'),
    '... not Foo->has_method(bling) (defined in main:: using symbol tables (no Sub::Name))'
);

ok( $Foo->has_method('bar'), '... Foo->has_method(bar) (defined in Foo)' );
ok( $Foo->has_method('baz'),
    '... Foo->has_method(baz) (typeglob aliased within Foo)' );
ok( $Foo->has_method('baaz'),
    '... Foo->has_method(baaz) (typeglob aliased within Foo)' );
ok( $Foo->has_method('floob'),
    '... Foo->has_method(floob) (defined in Foo:: using symbol tables and Sub::Name w/out package name)'
);
ok( $Foo->has_method('blah'),
    '... Foo->has_method(blah) (defined in main:: using fully qualified package name)'
);
ok( $Foo->has_method('bang'),
    '... Foo->has_method(bang) (defined in main:: using symbol tables and Sub::Name)'
);
ok( $Foo->has_method('evaled_foo'),
    '... Foo->has_method(evaled_foo) (evaled in main::)' );

my $OinkyBoinky = Class::MOP::Class->initialize('OinkyBoinky');

ok( $OinkyBoinky->has_method('elk'),
    "the method 'elk' is defined in OinkyBoinky" );

ok( !$OinkyBoinky->has_method('bar'),
    "the method 'bar' is not defined in OinkyBoinky" );

ok( my $bar = $OinkyBoinky->find_method_by_name('bar'),
    "but if you look in the inheritence chain then 'bar' does exist" );

is( reftype( $bar->body ), "CODE", "the returned value is a code ref" );

# calling get_method blessed them all
for my $method_name (
    qw/baaz
    bar
    baz
    floob
    blah
    bang
    bork
    evaled_foo
    FOO_CONSTANT/
    ) {
    isa_ok( $Foo->get_method($method_name), 'Class::MOP::Method' );
    {
        no strict 'refs';
        is( $Foo->get_method($method_name)->body,
            \&{ 'Foo::' . $method_name },
            '... body matches CODE ref in package for ' . $method_name );
    }
}

for my $method_name (
    qw/
    bling
    /
    ) {
    is( ref( $Foo->get_package_symbol( '&' . $method_name ) ), 'CODE',
        '... got the __ANON__ methods' );
    {
        no strict 'refs';
        is( $Foo->get_package_symbol( '&' . $method_name ),
            \&{ 'Foo::' . $method_name },
            '... symbol matches CODE ref in package for ' . $method_name );
    }
}

ok( !$Foo->has_method('blessed'),
    '... !Foo->has_method(blessed) (imported into Foo)' );
ok( !$Foo->has_method('boom'),
    '... !Foo->has_method(boom) (defined in main:: using symbol tables and Sub::Name w/out package name)'
);

ok( !$Foo->has_method('not_a_real_method'),
    '... !Foo->has_method(not_a_real_method) (does not exist)' );
is( $Foo->get_method('not_a_real_method'), undef,
    '... Foo->get_method(not_a_real_method) == undef' );

is_deeply(
    [ sort $Foo->get_method_list ],
    [qw(FOO_CONSTANT baaz bang bar baz blah bork cake evaled_foo floob foo pie)],
    '... got the right method list for Foo'
);

my @universal_methods = qw/isa can VERSION/;
push @universal_methods, 'DOES' if $] >= 5.010;

is_deeply(
    [
        map { $_->name => $_ }
        sort { $a->name cmp $b->name } $Foo->get_all_methods()
    ],
    [
        map { $_->name => $_ }
            map { $Foo->find_method_by_name($_) }
            sort qw(
            FOO_CONSTANT
            baaz
            bang
            bar
            baz
            blah
            bork
            cake
            evaled_foo
            floob
            foo
            pie
            ),
        @universal_methods,
    ],
    '... got the right list of applicable methods for Foo'
);

is( $Foo->remove_method('foo')->body, $foo, '... removed the foo method' );
ok( !$Foo->has_method('foo'),
    '... !Foo->has_method(foo) we just removed it' );
isnt( exception { Foo->foo }, undef, '... cannot call Foo->foo because it is not there' );

is_deeply(
    [ sort $Foo->get_method_list ],
    [qw(FOO_CONSTANT baaz bang bar baz blah bork cake evaled_foo floob pie)],
    '... got the right method list for Foo'
);

# ... test our class creator

my $Bar = Class::MOP::Class->create(
    package      => 'Bar',
    superclasses => ['Foo'],
    methods      => {
        foo => sub {'Bar::foo'},
        bar => sub {'Bar::bar'},
    }
);
isa_ok( $Bar, 'Class::MOP::Class' );

ok( $Bar->has_method('foo'), '... Bar->has_method(foo)' );
ok( $Bar->has_method('bar'), '... Bar->has_method(bar)' );

is( Bar->foo, 'Bar::foo', '... Bar->foo == Bar::foo' );
is( Bar->bar, 'Bar::bar', '... Bar->bar == Bar::bar' );

is( exception {
    $Bar->add_method( 'foo' => sub {'Bar::foo v2'} );
}, undef, '... overwriting a method is fine' );

is_deeply( [ Class::MOP::get_code_info( $Bar->get_method('foo')->body ) ],
    [ "Bar", "foo" ], "subname applied to anonymous method" );

ok( $Bar->has_method('foo'), '... Bar-> (still) has_method(foo)' );
is( Bar->foo, 'Bar::foo v2', '... Bar->foo == "Bar::foo v2"' );

is_deeply(
    [ sort $Bar->get_method_list ],
    [qw(bar foo meta)],
    '... got the right method list for Bar'
);

is_deeply(
    [
        map { $_->name => $_ }
        sort { $a->name cmp $b->name } $Bar->get_all_methods()
    ],
    [
        map { $_->name => $_ }
            sort { $a->name cmp $b->name } (
            $Foo->get_method('FOO_CONSTANT'),
            $Foo->get_method('baaz'),
            $Foo->get_method('bang'),
            $Bar->get_method('bar'),
            (
                map { $Foo->get_method($_) }
                    qw(
                    baz
                    blah
                    bork
                    cake
                    evaled_foo
                    floob
                    )
            ),
            $Bar->get_method('foo'),
            $Bar->get_method('meta'),
            $Foo->get_method('pie'),
            ( map { $Bar->find_next_method_by_name($_) } @universal_methods )
            )
    ],
    '... got the right list of applicable methods for Bar'
);

my $method = Class::MOP::Method->wrap(
    name         => 'objecty',
    package_name => 'Whatever',
    body         => sub {q{I am an object, and I feel an object's pain}},
);

Bar->meta->add_method( $method->name, $method );

my $new_method = Bar->meta->get_method('objecty');

isnt( $method, $new_method,
    'add_method clones method objects as they are added' );
is( $new_method->original_method, $method,
    '... the cloned method has the correct original method' )
        or diag $new_method->dump;

{
    package CustomAccessor;

    use Class::MOP;

    my $meta = Class::MOP::Class->initialize(__PACKAGE__);

    $meta->add_attribute(
        foo => (
            accessor => 'foo',
        )
    );

    {
        no warnings 'redefine', 'once';
        *foo = sub {
            my $self = shift;
            $self->{custom_store} = $_[0];
        };
    }

    $meta->add_around_method_modifier(
        'foo',
        sub {
            my $orig = shift;
            $orig->(@_);
        }
    );

    sub new {
        return bless {}, shift;
    }
}

{
    my $o   = CustomAccessor->new;
    my $str = 'string';

    $o->foo($str);

    is(
        $o->{custom_store}, $str,
        'Custom glob-assignment-created accessor still has method modifier'
    );
}

{
    # Since the sub reference below is not a closure, Perl caches it and uses
    # the same reference each time through the loop. See RT #48985 for the
    # bug.
    foreach my $ns ( qw( Foo2 Bar2 Baz2 ) ) {
        my $meta = Class::MOP::Class->create($ns);

        my $sub = sub { };

        $meta->add_method( 'foo', $sub );

        my $method = $meta->get_method('foo');
        ok( $method, 'Got the foo method back' );
    }
}

{
    package HasConstants;

    use constant FOO   => 1;
    use constant BAR   => [];
    use constant BAZ   => {};
    use constant UNDEF => undef;

    sub quux  {1}
    sub thing {1}
}

my $HC = Class::MOP::Class->initialize('HasConstants');

is_deeply(
    [ sort $HC->get_method_list ],
    [qw( BAR BAZ FOO UNDEF quux thing )],
    'get_method_list handles constants properly'
);

is_deeply(
    [ sort map { $_->name } $HC->_get_local_methods ],
    [qw( BAR BAZ FOO UNDEF quux thing )],
    '_get_local_methods handles constants properly'
);

{
    package DeleteFromMe;
    sub foo { 1 }
}

{
    my $DFMmeta = Class::MOP::Class->initialize('DeleteFromMe');
    ok($DFMmeta->get_method('foo'));

    delete $DeleteFromMe::{foo};

    ok(!$DFMmeta->get_method('foo'));
    ok(!DeleteFromMe->can('foo'));
}

{
    my $baz_meta = Class::MOP::Class->initialize('Baz');
    $baz_meta->add_method(foo => sub { });
    my $stash = Package::Stash->new('Baz');
    $stash->remove_symbol('&foo');
    is_deeply([$baz_meta->get_method_list], [], "method is deleted");
    ok(!Baz->can('foo'), "Baz can't foo");
}


done_testing;
