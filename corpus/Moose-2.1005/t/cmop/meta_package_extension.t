use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{
    package My::Package::Stash;
    use strict;
    use warnings;

    use base 'Package::Stash';

    use metaclass;

    use Symbol 'gensym';

    __PACKAGE__->meta->add_attribute(
        'namespace' => (
            reader  => 'namespace',
            default => sub { {} }
        )
    );

    sub new {
        my $class = shift;
        $class->meta->new_object(__INSTANCE__ => $class->SUPER::new(@_));
    }

    sub add_symbol {
        my ($self, $variable, $initial_value) = @_;

        (my $name = $variable) =~ s/^[\$\@\%\&]//;

        my $glob = gensym();
        *{$glob} = $initial_value if defined $initial_value;
        $self->namespace->{$name} = *{$glob};
    }
}

{
    package My::Meta::Package;

    use strict;
    use warnings;

    use base 'Class::MOP::Package';

    sub _package_stash {
        $_[0]->{_package_stash} ||= My::Package::Stash->new($_[0]->name);
    }
}

# No actually package Foo exists :)
my $meta = My::Meta::Package->initialize('Foo');

isa_ok($meta, 'My::Meta::Package');
isa_ok($meta, 'Class::MOP::Package');

ok(!defined($Foo::{foo}), '... the %foo slot has not been created yet');
ok(!$meta->has_package_symbol('%foo'), '... the meta agrees');

is( exception {
    $meta->add_package_symbol('%foo' => { one => 1 });
}, undef, '... the %foo symbol is created succcessfully' );

ok(!defined($Foo::{foo}), '... the %foo slot has not been created in the actual Foo package');
ok($meta->has_package_symbol('%foo'), '... the meta agrees');

my $foo = $meta->get_package_symbol('%foo');
is_deeply({ one => 1 }, $foo, '... got the right package variable back');

$foo->{two} = 2;

is($foo, $meta->get_package_symbol('%foo'), '... our %foo is the same as the metas');

ok(!defined($Foo::{bar}), '... the @bar slot has not been created yet');

is( exception {
    $meta->add_package_symbol('@bar' => [ 1, 2, 3 ]);
}, undef, '... created @Foo::bar successfully' );

ok(!defined($Foo::{bar}), '... the @bar slot has still not been created');

ok(!defined($Foo::{baz}), '... the %baz slot has not been created yet');

is( exception {
    $meta->add_package_symbol('%baz');
}, undef, '... created %Foo::baz successfully' );

ok(!defined($Foo::{baz}), '... the %baz slot has still not been created');

done_testing;
