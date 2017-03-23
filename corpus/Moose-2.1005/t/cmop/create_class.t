use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

my $Point = Class::MOP::Class->create('Point' => (
    version    => '0.01',
    attributes => [
        Class::MOP::Attribute->new('x' => (
            reader   => 'x',
            init_arg => 'x'
        )),
        Class::MOP::Attribute->new('y' => (
            accessor => 'y',
            init_arg => 'y'
        )),
    ],
    methods => {
        'new' => sub {
            my $class = shift;
            my $instance = $class->meta->new_object(@_);
            bless $instance => $class;
        },
        'clear' => sub {
            my $self = shift;
            $self->{'x'} = 0;
            $self->{'y'} = 0;
        }
    }
));

my $Point3D = Class::MOP::Class->create('Point3D' => (
    version      => '0.01',
    superclasses => [ 'Point' ],
    attributes => [
        Class::MOP::Attribute->new('z' => (
            default  => 123
        )),
    ],
    methods => {
        'clear' => sub {
            my $self = shift;
            $self->{'z'} = 0;
            $self->SUPER::clear();
        }
    }
));

isa_ok($Point, 'Class::MOP::Class');
isa_ok($Point3D, 'Class::MOP::Class');

# ... test the classes themselves

my $point = Point->new('x' => 2, 'y' => 3);
isa_ok($point, 'Point');

can_ok($point, 'x');
can_ok($point, 'y');
can_ok($point, 'clear');

{
    my $meta = $point->meta;
    is($meta, Point->meta(), '... got the meta from the instance too');
}

is($point->y, 3, '... the y attribute was initialized correctly through the metaobject');

$point->y(42);
is($point->y, 42, '... the y attribute was set properly with the accessor');

is($point->x, 2, '... the x attribute was initialized correctly through the metaobject');

isnt( exception {
    $point->x(42);
}, undef, '... cannot write to a read-only accessor' );
is($point->x, 2, '... the x attribute was not altered');

$point->clear();

is($point->y, 0, '... the y attribute was cleared correctly');
is($point->x, 0, '... the x attribute was cleared correctly');

my $point3d = Point3D->new('x' => 1, 'y' => 2, 'z' => 3);
isa_ok($point3d, 'Point3D');
isa_ok($point3d, 'Point');

{
    my $meta = $point3d->meta;
    is($meta, Point3D->meta(), '... got the meta from the instance too');
}

can_ok($point3d, 'x');
can_ok($point3d, 'y');
can_ok($point3d, 'clear');

is($point3d->x, 1, '... the x attribute was initialized correctly through the metaobject');
is($point3d->y, 2, '... the y attribute was initialized correctly through the metaobject');
is($point3d->{'z'}, 3, '... the z attribute was initialized correctly through the metaobject');

{
    my $point3d = Point3D->new();
    isa_ok($point3d, 'Point3D');

    is($point3d->x, undef, '... the x attribute was not initialized');
    is($point3d->y, undef, '... the y attribute was not initialized');
    is($point3d->{'z'}, 123, '... the z attribute was initialized correctly through the metaobject');

}

done_testing;
