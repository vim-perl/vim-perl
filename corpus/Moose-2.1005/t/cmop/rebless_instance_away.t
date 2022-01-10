#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Class::MOP;

my @calls;

do {
    package My::Meta::Class;
    use base 'Class::MOP::Class';

    sub rebless_instance_away {
        push @calls, [@_];
        shift->SUPER::rebless_instance_away(@_);
    }
};

do {
    package Parent;
    use metaclass 'My::Meta::Class';

    package Child;
    use metaclass 'My::Meta::Class';
    use base 'Parent';
};

my $person = Parent->meta->new_object;
Child->meta->rebless_instance($person);

is(@calls, 1, "one call to rebless_instance_away");
is($calls[0][0]->name, 'Parent', 'rebless_instance_away is called on the old metaclass');
is($calls[0][1], $person, 'with the instance');
is($calls[0][2]->name, 'Child', 'and the new metaclass');
splice @calls;

Child->meta->rebless_instance($person, foo => 1);
is($calls[0][0]->name, 'Child');
is($calls[0][1], $person);
is($calls[0][2]->name, 'Child');
is($calls[0][3], 'foo');
is($calls[0][4], 1);
splice @calls;

done_testing;
