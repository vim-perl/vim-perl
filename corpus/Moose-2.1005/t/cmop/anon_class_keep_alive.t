use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Class::MOP;

my $anon_class_name;
my $anon_meta_name;
{
  package Foo;
  use strict;
  use warnings;
  use metaclass;

  sub make_anon_instance{
    my $self = shift;
    my $class = ref $self || $self;

    my $anon_class = Class::MOP::Class->create_anon_class(superclasses => [$class]);
    $anon_class_name = $anon_class->name;
    $anon_meta_name = Scalar::Util::blessed($anon_class);
    $anon_class->add_attribute( $_, reader => $_ ) for qw/bar baz/;

    my $obj = $anon_class->new_object(bar => 'a', baz => 'b');
    return $obj;
  }

  sub foo{ 'foo' }

  1;
}

my $instance = Foo->make_anon_instance;

isa_ok($instance, $anon_class_name);
isa_ok($instance->meta, $anon_meta_name);
isa_ok($instance, 'Foo', '... Anonymous instance isa Foo');

ok($instance->can('foo'), '... Anonymous instance can foo');
ok($instance->meta->find_method_by_name('foo'), '... Anonymous instance has method foo');

ok($instance->meta->has_attribute('bar'), '... Anonymous instance still has attribute bar');
ok($instance->meta->has_attribute('baz'), '... Anonymous instance still has attribute baz');
is($instance->bar, 'a', '... Anonymous instance still has correct bar value');
is($instance->baz, 'b', '... Anonymous instance still has correct baz value');

is_deeply([$instance->meta->class_precedence_list],
          [$anon_class_name, 'Foo'],
          '... Anonymous instance has class precedence list',
         );

done_testing;
