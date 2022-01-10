use strict;
use warnings;

use Class::MOP;
use Class::MOP::Class;
use Test::More;
use Test::Fatal;

my %results;

{

    package Base;
    use metaclass;
    sub hey { $results{base}++ }
}

for my $wrap (qw(before after)) {
    my $meta = Class::MOP::Class->create_anon_class(
        superclasses => [ 'Base', 'Class::MOP::Object' ] );
    my $alter = "add_${wrap}_method_modifier";
    $meta->$alter(
        'hey' => sub {
            $results{wrapped}++;
            $_ = 'barf';    # 'barf' would replace the cached wrapper subref
        }
    );

    %results = ();
    my $o = $meta->get_meta_instance->create_instance;
    isa_ok( $o, 'Base' );
    is( exception {
        $o->hey;
        $o->hey
            ; # this would die with 'Can't use string ("barf") as a subroutine ref while "strict refs" in use'
    }, undef, 'wrapped doesn\'t die when $_ gets changed' );
    is_deeply(
        \%results, { base => 2, wrapped => 2 },
        'saw expected calls to wrappers'
    );
}

{
    my $meta = Class::MOP::Class->create_anon_class(
        superclasses => [ 'Base', 'Class::MOP::Object' ] );
    for my $wrap (qw(before after)) {
        my $alter = "add_${wrap}_method_modifier";
        $meta->$alter(
            'hey' => sub {
                $results{wrapped}++;
                $_ = 'barf';  # 'barf' would replace the cached wrapper subref
            }
        );
    }

    %results = ();
    my $o = $meta->get_meta_instance->create_instance;
    isa_ok( $o, 'Base' );
    is( exception {
        $o->hey;
        $o->hey
            ; # this would die with 'Can't use string ("barf") as a subroutine ref while "strict refs" in use'
    }, undef, 'double-wrapped doesn\'t die when $_ gets changed' );
    is_deeply(
        \%results, { base => 2, wrapped => 4 },
        'saw expected calls to wrappers'
    );
}

done_testing;
