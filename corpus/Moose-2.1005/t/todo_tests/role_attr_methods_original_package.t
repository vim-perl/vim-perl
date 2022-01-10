use strict;
use warnings;

use Test::More 0.88;

{
    package Some::Role;
    use Moose::Role;

    has 'thing' => (
        is => 'ro',
    );

    sub foo { 42 }
}

{
    package Some::Class;
    use Moose;

    with 'Some::Role';
}

my $attr = Some::Class->meta()->get_attribute('thing');

# See RT #84563
for my $method ( @{ $attr->associated_methods() } ) {
TODO: {
        local $TODO
            = q{Methods generated from role-provided attributes don't know their original package};
        is(
            $method->original_package_name(),
            'Some::Role',
            'original_package_name for methods generated from role attribute should match the role'
        );
    }
}

is(
    Some::Class->meta()->get_method('foo')->original_package_name(),
    'Some::Role',
    'original_package_name for methods from role should match the role'
);

done_testing();
