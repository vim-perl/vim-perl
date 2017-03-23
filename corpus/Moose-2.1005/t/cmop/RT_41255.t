use strict;
use Test::More;
use Test::Fatal;

use Class::MOP;

{
    package BaseClass;
    sub m1 { 1 }
    sub m2 { 2 }
    sub m3 { 3 }
    sub m4 { 4 }
    sub m5 { 5 }

    package Derived;
    use base qw(BaseClass);

    sub m1;
    sub m2 ();
    sub m3 :method;
    sub m4; m4() if 0;
    sub m5; our $m5;;
}

my $meta = Class::MOP::Class->initialize('Derived');
my %methods = map { $_ => $meta->find_method_by_name($_) } 'm1' .. 'm5';

while (my ($name, $meta_method) = each %methods) {
    is $meta_method->fully_qualified_name, "Derived::${name}";
    like( exception { $meta_method->execute }, qr/Undefined subroutine .* called at/ );
}

{
    package Derived;
    eval <<'EOC';

    sub m1         { 'affe'  }
    sub m2 ()      { 'apan'  }
    sub m3 :method { 'tiger' }
    sub m4         { 'birne' }
    sub m5         { 'apfel' }

EOC
}

while (my ($name, $meta_method) = each %methods) {
    is $meta_method->fully_qualified_name, "Derived::${name}";
    is( exception { $meta_method->execute }, undef );
}

done_testing;
