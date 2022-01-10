use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use Test::More;

use Class::Load qw(is_class_loaded);

use lib catdir($FindBin::Bin, 'lib');

{
    package Foo;

    use strict;
    use warnings;

    use metaclass 'MyMetaClass' => (
        'attribute_metaclass' => 'MyMetaClass::Attribute',
        'instance_metaclass'  => 'MyMetaClass::Instance',
        'method_metaclass'    => 'MyMetaClass::Method',
        'random_metaclass'    => 'MyMetaClass::Random',
    );
}

my $meta = Foo->meta;

isa_ok($meta, 'MyMetaClass', '... Correct metaclass');
ok(is_class_loaded('MyMetaClass'), '... metaclass loaded');

is($meta->attribute_metaclass, 'MyMetaClass::Attribute',  '... Correct attribute metaclass');
ok(is_class_loaded('MyMetaClass::Attribute'), '... attribute metaclass loaded');

is($meta->instance_metaclass,  'MyMetaClass::Instance',  '... Correct instance metaclass');
ok(is_class_loaded('MyMetaClass::Instance'), '... instance metaclass loaded');

is($meta->method_metaclass,    'MyMetaClass::Method',  '... Correct method metaclass');
ok(is_class_loaded('MyMetaClass::Method'), '... method metaclass loaded');

done_testing;
