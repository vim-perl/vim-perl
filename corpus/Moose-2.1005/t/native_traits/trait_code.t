use strict;
use warnings;

use lib 't/lib';

use Moose ();
use NoInlineAttribute;
use Test::More;
use Test::Moose;

{
    my $name = 'Foo1';

    sub build_class {
        my ( $attr1, $attr2, $attr3, $no_inline ) = @_;

        my $class = Moose::Meta::Class->create(
            $name++,
            superclasses => ['Moose::Object'],
        );

        my @traits = 'Code';
        push @traits, 'NoInlineAttribute'
            if $no_inline;

        $class->add_attribute(
            callback => (
                traits   => \@traits,
                isa      => 'CodeRef',
                required => 1,
                handles  => { 'invoke_callback' => 'execute' },
                %{ $attr1 || {} },
            )
        );

        $class->add_attribute(
            callback_method => (
                traits   => \@traits,
                isa      => 'CodeRef',
                required => 1,
                handles  => { 'invoke_method_callback' => 'execute_method' },
                %{ $attr2 || {} },
            )
        );

        $class->add_attribute(
            multiplier => (
                traits   => \@traits,
                isa      => 'CodeRef',
                required => 1,
                handles  => { 'multiply' => 'execute' },
                %{ $attr3 || {} },
            )
        );

        return $class->name;
    }
}

{
    my $i;

    my %subs = (
        callback        => sub { ++$i },
        callback_method => sub { shift->multiply(@_) },
        multiplier      => sub { $_[0] * 2 },
    );

    run_tests( build_class, \$i, \%subs );

    run_tests( build_class( undef, undef, undef, 1 ), \$i, \%subs );

    run_tests(
        build_class(
            {
                lazy => 1, default => sub { $subs{callback} }
            }, {
                lazy => 1, default => sub { $subs{callback_method} }
            }, {
                lazy => 1, default => sub { $subs{multiplier} }
            },
        ),
        \$i,
    );
}

sub run_tests {
    my ( $class, $iref, @args ) = @_;

    ok(
        !$class->can($_),
        "Code trait didn't create reader method for $_"
    ) for qw(callback callback_method multiplier);

    with_immutable {
        ${$iref} = 0;
        my $obj = $class->new(@args);

        $obj->invoke_callback;

        is( ${$iref}, 1, '$i is 1 after invoke_callback' );

        is(
            $obj->invoke_method_callback(3), 6,
            'invoke_method_callback calls multiply with @_'
        );

        is( $obj->multiply(3), 6, 'multiple double value' );
    }
    $class;
}

done_testing;
