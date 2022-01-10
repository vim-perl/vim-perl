#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package My::Trait;
    use Moose::Role;

    sub reversed_name {
        my $self = shift;
        scalar reverse $self->name;
    }
}

{
    package My::Class;
    use Moose -traits => [
        'My::Trait' => {
            -alias => {
                reversed_name => 'enam',
            },
        },
    ];
}

{
    package My::Other::Class;
    use Moose -traits => [
        'My::Trait' => {
            -alias => {
                reversed_name => 'reversed',
            },
            -excludes => 'reversed_name',
        },
    ];
}

my $meta = My::Class->meta;
is($meta->enam, 'ssalC::yM', 'parameterized trait applied');
ok(!$meta->can('reversed'), "the method was not installed under the other class' alias");

my $other_meta = My::Other::Class->meta;
is($other_meta->reversed, 'ssalC::rehtO::yM', 'parameterized trait applied');
ok(!$other_meta->can('enam'), "the method was not installed under the other class' alias");
ok(!$other_meta->can('reversed_name'), "the method was not installed under the original name when that was excluded");

done_testing;
