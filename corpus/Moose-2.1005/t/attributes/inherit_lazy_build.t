use strict;
use warnings;

use Test::More;

{

    package Parent;
    use Moose;
    has attr => ( is => 'rw', isa => 'Str' );
}

{
    package Child;
    use Moose;
    extends 'Parent';

    has '+attr' => ( lazy_build => 1 );

    sub _build_attr {
        return 'value';
    }
}

my $parent = Parent->new();
my $child  = Child->new();

ok(
    !$parent->meta->get_attribute('attr')->is_lazy_build,
    'attribute in parent does not have lazy_build trait'
);
ok(
    !$parent->meta->get_attribute('attr')->is_lazy,
    'attribute in parent does not have lazy trait'
);
ok(
    !$parent->meta->get_attribute('attr')->has_builder,
    'attribute in parent does not have a builder method'
);
ok(
    !$parent->meta->get_attribute('attr')->has_clearer,
    'attribute in parent does not have a clearer method'
);
ok(
    !$parent->meta->get_attribute('attr')->has_predicate,
    'attribute in parent does not have a predicate method'
);

ok(
    $child->meta->get_attribute('attr')->is_lazy_build,
    'attribute in child has the lazy_build trait'
);
ok(
    $child->meta->get_attribute('attr')->is_lazy,
    'attribute in child has the lazy trait'
);
ok(
    $child->meta->get_attribute('attr')->has_builder,
    'attribute in child has a builder method'
);
ok(
    $child->meta->get_attribute('attr')->has_clearer,
    'attribute in child has a clearer method'
);
ok(
    $child->meta->get_attribute('attr')->has_predicate,
    'attribute in child has a predicate method'
);

is(
    $child->attr, 'value',
    'attribute defined as lazy_build in child is properly built'
);

done_testing;
