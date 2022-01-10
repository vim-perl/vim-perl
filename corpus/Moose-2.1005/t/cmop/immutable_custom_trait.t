use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

{

    package My::Meta;

    use strict;
    use warnings;

    use base 'Class::MOP::Class';

    sub initialize {
        shift->SUPER::initialize(
            @_,
            immutable_trait => 'My::Meta::Class::Immutable::Trait',
        );
    }
}

{
    package My::Meta::Class::Immutable::Trait;

    use MRO::Compat;
    use base 'Class::MOP::Class::Immutable::Trait';

    sub another_method { 42 }

    sub superclasses {
        my $orig = shift;
        my $self = shift;
        $self->$orig(@_);
    }
}

{
    package Foo;

    use strict;
    use warnings;
    use metaclass;

    __PACKAGE__->meta->add_attribute('foo');

    __PACKAGE__->meta->make_immutable;
}

{
    package Bar;

    use strict;
    use warnings;
    use metaclass 'My::Meta';

    use base 'Foo';

    __PACKAGE__->meta->add_attribute('bar');

    ::is( ::exception { __PACKAGE__->meta->make_immutable }, undef, 'can safely make a class immutable when it has a custom metaclass and immutable trait' );
}

{
    can_ok( Bar->meta, 'another_method' );
    is( Bar->meta->another_method, 42, 'another_method returns expected value' );
    is_deeply(
        [ Bar->meta->superclasses ], ['Foo'],
        'Bar->meta->superclasses returns expected value after immutabilization'
    );
}

done_testing;
