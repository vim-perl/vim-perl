use strict;
use warnings;

use Test::More;
use Class::MOP;

my $meta_class = Class::MOP::Class->create_anon_class;

my %methods      = map { $_->name => 1 } $meta_class->get_all_methods();
my %method_names = map { $_       => 1 } $meta_class->get_all_method_names();

my @universal_methods = qw/isa can VERSION/;
push @universal_methods, 'DOES' if $] >= 5.010;

for my $method (@universal_methods) {
    ok(
        $meta_class->find_method_by_name($method),
        "find_method_by_name finds UNIVERSAL method $method"
    );
    ok(
        $meta_class->find_next_method_by_name($method),
        "find_next_method_by_name finds UNIVERSAL method $method"
    );
    ok(
        scalar $meta_class->find_all_methods_by_name($method),
        "find_all_methods_by_name finds UNIVERSAL method $method"
    );
    ok(
        $methods{$method},
        "get_all_methods includes $method from UNIVERSAL"
    );
    ok(
        $method_names{$method},
        "get_all_method_names includes $method from UNIVERSAL"
    );
}

done_testing;
