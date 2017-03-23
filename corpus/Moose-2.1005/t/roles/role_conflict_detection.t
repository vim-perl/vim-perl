#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

=pod

Mutually recursive roles.

=cut

{
    package Role::Foo;
    use Moose::Role;

    requires 'foo';

    sub bar { 'Role::Foo::bar' }

    package Role::Bar;
    use Moose::Role;

    requires 'bar';

    sub foo { 'Role::Bar::foo' }
}

{
    package My::Test1;
    use Moose;

    ::is( ::exception {
        with 'Role::Foo', 'Role::Bar';
    }, undef, '... our mutually recursive roles combine okay' );

    package My::Test2;
    use Moose;

    ::is( ::exception {
        with 'Role::Bar', 'Role::Foo';
    }, undef, '... our mutually recursive roles combine okay (no matter what order)' );
}

my $test1 = My::Test1->new;
isa_ok($test1, 'My::Test1');

ok($test1->does('Role::Foo'), '... $test1 does Role::Foo');
ok($test1->does('Role::Bar'), '... $test1 does Role::Bar');

can_ok($test1, 'foo');
can_ok($test1, 'bar');

is($test1->foo, 'Role::Bar::foo', '... $test1->foo worked');
is($test1->bar, 'Role::Foo::bar', '... $test1->bar worked');

my $test2 = My::Test2->new;
isa_ok($test2, 'My::Test2');

ok($test2->does('Role::Foo'), '... $test2 does Role::Foo');
ok($test2->does('Role::Bar'), '... $test2 does Role::Bar');

can_ok($test2, 'foo');
can_ok($test2, 'bar');

is($test2->foo, 'Role::Bar::foo', '... $test2->foo worked');
is($test2->bar, 'Role::Foo::bar', '... $test2->bar worked');

# check some meta-stuff

ok(Role::Foo->meta->has_method('bar'), '... it still has the bar method');
ok(Role::Foo->meta->requires_method('foo'), '... it still has the required foo method');

ok(Role::Bar->meta->has_method('foo'), '... it still has the foo method');
ok(Role::Bar->meta->requires_method('bar'), '... it still has the required bar method');

=pod

Role method conflicts

=cut

{
    package Role::Bling;
    use Moose::Role;

    sub bling { 'Role::Bling::bling' }

    package Role::Bling::Bling;
    use Moose::Role;

    sub bling { 'Role::Bling::Bling::bling' }
}

{
    package My::Test3;
    use Moose;

    ::like( ::exception {
        with 'Role::Bling', 'Role::Bling::Bling';
    }, qr/Due to a method name conflict in roles 'Role::Bling' and 'Role::Bling::Bling', the method 'bling' must be implemented or excluded by 'My::Test3'/, '... role methods conflict and method was required' );

    package My::Test4;
    use Moose;

    ::is( ::exception {
        with 'Role::Bling';
        with 'Role::Bling::Bling';
    }, undef, '... role methods didnt conflict when manually combined' );

    package My::Test5;
    use Moose;

    ::is( ::exception {
        with 'Role::Bling::Bling';
        with 'Role::Bling';
    }, undef, '... role methods didnt conflict when manually combined (in opposite order)' );

    package My::Test6;
    use Moose;

    ::is( ::exception {
        with 'Role::Bling::Bling', 'Role::Bling';
    }, undef, '... role methods didnt conflict when manually resolved' );

    sub bling { 'My::Test6::bling' }

    package My::Test7;
    use Moose;

    ::is( ::exception {
        with 'Role::Bling::Bling', { -excludes => ['bling'] }, 'Role::Bling';
    }, undef, '... role methods didnt conflict when one of the conflicting methods is excluded' );

    package My::Test8;
    use Moose;

    ::is( ::exception {
        with 'Role::Bling::Bling', { -excludes => ['bling'], -alias => { bling => 'bling_bling' } }, 'Role::Bling';
    }, undef, '... role methods didnt conflict when one of the conflicting methods is excluded and aliased' );
}

ok(!My::Test3->meta->has_method('bling'), '... we didnt get any methods in the conflict');
ok(My::Test4->meta->has_method('bling'), '... we did get the method when manually dealt with');
ok(My::Test5->meta->has_method('bling'), '... we did get the method when manually dealt with');
ok(My::Test6->meta->has_method('bling'), '... we did get the method when manually dealt with');
ok(My::Test7->meta->has_method('bling'), '... we did get the method when manually dealt with');
ok(My::Test8->meta->has_method('bling'), '... we did get the method when manually dealt with');
ok(My::Test8->meta->has_method('bling_bling'), '... we did get the aliased method too');

ok(!My::Test3->does('Role::Bling'), '... our class does() the correct roles');
ok(!My::Test3->does('Role::Bling::Bling'), '... our class does() the correct roles');
ok(My::Test4->does('Role::Bling'), '... our class does() the correct roles');
ok(My::Test4->does('Role::Bling::Bling'), '... our class does() the correct roles');
ok(My::Test5->does('Role::Bling'), '... our class does() the correct roles');
ok(My::Test5->does('Role::Bling::Bling'), '... our class does() the correct roles');
ok(My::Test6->does('Role::Bling'), '... our class does() the correct roles');
ok(My::Test6->does('Role::Bling::Bling'), '... our class does() the correct roles');
ok(My::Test7->does('Role::Bling'), '... our class does() the correct roles');
ok(My::Test7->does('Role::Bling::Bling'), '... our class does() the correct roles');
ok(My::Test8->does('Role::Bling'), '... our class does() the correct roles');
ok(My::Test8->does('Role::Bling::Bling'), '... our class does() the correct roles');

is(My::Test4->bling, 'Role::Bling::bling', '... and we got the first method that was added');
is(My::Test5->bling, 'Role::Bling::Bling::bling', '... and we got the first method that was added');
is(My::Test6->bling, 'My::Test6::bling', '... and we got the local method');
is(My::Test7->bling, 'Role::Bling::bling', '... and we got the non-excluded method');
is(My::Test8->bling, 'Role::Bling::bling', '... and we got the non-excluded/aliased method');
is(My::Test8->bling_bling, 'Role::Bling::Bling::bling', '... and the aliased method comes from the correct role');

# check how this affects role compostion

{
    package Role::Bling::Bling::Bling;
    use Moose::Role;

    with 'Role::Bling::Bling';

    sub bling { 'Role::Bling::Bling::Bling::bling' }
}

ok(Role::Bling::Bling->meta->has_method('bling'), '... still got the bling method in Role::Bling::Bling');
ok(Role::Bling::Bling->meta->does_role('Role::Bling::Bling'), '... our role correctly does() the other role');
ok(Role::Bling::Bling::Bling->meta->has_method('bling'), '... dont have the bling method in Role::Bling::Bling::Bling');
is(Role::Bling::Bling::Bling->meta->get_method('bling')->(),
    'Role::Bling::Bling::Bling::bling',
    '... still got the bling method in Role::Bling::Bling::Bling');


=pod

Role attribute conflicts

=cut

{
    package Role::Boo;
    use Moose::Role;

    has 'ghost' => (is => 'ro', default => 'Role::Boo::ghost');

    package Role::Boo::Hoo;
    use Moose::Role;

    has 'ghost' => (is => 'ro', default => 'Role::Boo::Hoo::ghost');
}

{
    package My::Test7;
    use Moose;

    ::like( ::exception {
        with 'Role::Boo', 'Role::Boo::Hoo';
    }, qr/We have encountered an attribute conflict.+ghost/ );

    package My::Test8;
    use Moose;

    ::is( ::exception {
        with 'Role::Boo';
        with 'Role::Boo::Hoo';
    }, undef, '... role attrs didnt conflict when manually combined' );

    package My::Test9;
    use Moose;

    ::is( ::exception {
        with 'Role::Boo::Hoo';
        with 'Role::Boo';
    }, undef, '... role attrs didnt conflict when manually combined' );

    package My::Test10;
    use Moose;

    has 'ghost' => (is => 'ro', default => 'My::Test10::ghost');

    ::like( ::exception {
        with 'Role::Boo', 'Role::Boo::Hoo';
    }, qr/We have encountered an attribute conflict/, '... role attrs conflict and cannot be manually disambiguted' );

}

ok(!My::Test7->meta->has_attribute('ghost'), '... we didnt get any attributes in the conflict');
ok(My::Test8->meta->has_attribute('ghost'), '... we did get an attributes when manually composed');
ok(My::Test9->meta->has_attribute('ghost'), '... we did get an attributes when manually composed');
ok(My::Test10->meta->has_attribute('ghost'), '... we did still have an attribute ghost (conflict does not mess with class)');

ok(!My::Test7->does('Role::Boo'), '... our class does() the correct roles');
ok(!My::Test7->does('Role::Boo::Hoo'), '... our class does() the correct roles');
ok(My::Test8->does('Role::Boo'), '... our class does() the correct roles');
ok(My::Test8->does('Role::Boo::Hoo'), '... our class does() the correct roles');
ok(My::Test9->does('Role::Boo'), '... our class does() the correct roles');
ok(My::Test9->does('Role::Boo::Hoo'), '... our class does() the correct roles');
ok(!My::Test10->does('Role::Boo'), '... our class does() the correct roles');
ok(!My::Test10->does('Role::Boo::Hoo'), '... our class does() the correct roles');

can_ok('My::Test8', 'ghost');
can_ok('My::Test9', 'ghost');
can_ok('My::Test10', 'ghost');

is(My::Test8->new->ghost, 'Role::Boo::ghost', '... got the expected default attr value');
is(My::Test9->new->ghost, 'Role::Boo::Hoo::ghost', '... got the expected default attr value');
is(My::Test10->new->ghost, 'My::Test10::ghost', '... got the expected default attr value');

=pod

Role override method conflicts

=cut

{
    package Role::Plot;
    use Moose::Role;

    override 'twist' => sub {
        super() . ' -> Role::Plot::twist';
    };

    package Role::Truth;
    use Moose::Role;

    override 'twist' => sub {
        super() . ' -> Role::Truth::twist';
    };
}

{
    package My::Test::Base;
    use Moose;

    sub twist { 'My::Test::Base::twist' }

    package My::Test11;
    use Moose;

    extends 'My::Test::Base';

    ::is( ::exception {
        with 'Role::Truth';
    }, undef, '... composed the role with override okay' );

    package My::Test12;
    use Moose;

    extends 'My::Test::Base';

    ::is( ::exception {
       with 'Role::Plot';
    }, undef, '... composed the role with override okay' );

    package My::Test13;
    use Moose;

    ::isnt( ::exception {
        with 'Role::Plot';
    }, undef, '... cannot compose it because we have no superclass' );

    package My::Test14;
    use Moose;

    extends 'My::Test::Base';

    ::like( ::exception {
        with 'Role::Plot', 'Role::Truth';
    }, qr/Two \'override\' methods of the same name encountered/, '... cannot compose it because we have no superclass' );
}

ok(My::Test11->meta->has_method('twist'), '... the twist method has been added');
ok(My::Test12->meta->has_method('twist'), '... the twist method has been added');
ok(!My::Test13->meta->has_method('twist'), '... the twist method has not been added');
ok(!My::Test14->meta->has_method('twist'), '... the twist method has not been added');

ok(!My::Test11->does('Role::Plot'), '... our class does() the correct roles');
ok(My::Test11->does('Role::Truth'), '... our class does() the correct roles');
ok(!My::Test12->does('Role::Truth'), '... our class does() the correct roles');
ok(My::Test12->does('Role::Plot'), '... our class does() the correct roles');
ok(!My::Test13->does('Role::Plot'), '... our class does() the correct roles');
ok(!My::Test14->does('Role::Truth'), '... our class does() the correct roles');
ok(!My::Test14->does('Role::Plot'), '... our class does() the correct roles');

is(My::Test11->twist(), 'My::Test::Base::twist -> Role::Truth::twist', '... got the right method return');
is(My::Test12->twist(), 'My::Test::Base::twist -> Role::Plot::twist', '... got the right method return');
ok(!My::Test13->can('twist'), '... no twist method here at all');
is(My::Test14->twist(), 'My::Test::Base::twist', '... got the right method return (from superclass)');

{
    package Role::Reality;
    use Moose::Role;

    ::like( ::exception {
        with 'Role::Plot';
    }, qr/A local method of the same name as been found/, '... could not compose roles here, it dies' );

    sub twist {
        'Role::Reality::twist';
    }
}

ok(Role::Reality->meta->has_method('twist'), '... the twist method has not been added');
#ok(!Role::Reality->meta->does_role('Role::Plot'), '... our role does() the correct roles');
is(Role::Reality->meta->get_method('twist')->(),
    'Role::Reality::twist',
    '... the twist method returns the right value');

# Ovid's test case from rt.cpan.org #44
{
    package Role1;
    use Moose::Role;

    sub foo {}
}
{
    package Role2;
    use Moose::Role;

    sub foo {}
}
{
    package Conflicts;
    use Moose;

    ::like( ::exception {
        with qw(Role1 Role2);
    }, qr/Due to a method name conflict in roles 'Role1' and 'Role2', the method 'foo' must be implemented or excluded by 'Conflicts'/ );
}

=pod

Role conflicts between attributes and methods

[15:23]  <kolibrie> when class defines method and role defines method, class wins
[15:24]  <kolibrie> when class 'has'   method and role defines method, class wins
[15:24]  <kolibrie> when class defines method and role 'has'   method, role wins
[15:24]  <kolibrie> when class 'has'   method and role 'has'   method, role wins
[15:24]  <kolibrie> which means when class 'has' method and two roles 'has' method, no tiebreak is detected
[15:24]  <perigrin> this is with role and has declaration in the exact same order in every case?
[15:25]  <kolibrie> yes
[15:25]  <perigrin> interesting
[15:25]  <kolibrie> that's what I thought
[15:26]  <kolibrie> does that sound like something I should write a test for?
[15:27]  <perigrin> stevan, ping?
[15:27]  <perigrin> I'm not sure what the right answer for composition is.
[15:27]  <perigrin> who should win
[15:27]  <perigrin> if I were to guess I'd say the class should always win.
[15:27]  <kolibrie> that would be my guess, but I thought I would ask to make sure
[15:29]  <stevan> kolibrie: please write a test
[15:29]  <stevan> I am not exactly sure who should win either,.. but I suspect it is not working correctly right now
[15:29]  <stevan> I know exactly why it is doing what it is doing though

Now I have to decide actually what happens, and how to fix it.
- SL

{
    package Role::Method;
    use Moose::Role;

    sub ghost { 'Role::Method::ghost' }

    package Role::Method2;
    use Moose::Role;

    sub ghost { 'Role::Method2::ghost' }

    package Role::Attribute;
    use Moose::Role;

    has 'ghost' => (is => 'ro', default => 'Role::Attribute::ghost');

    package Role::Attribute2;
    use Moose::Role;

    has 'ghost' => (is => 'ro', default => 'Role::Attribute2::ghost');
}

{
    package My::Test15;
    use Moose;

    ::lives_ok {
       with 'Role::Method';
    } '... composed the method role into the method class';

    sub ghost { 'My::Test15::ghost' }

    package My::Test16;
    use Moose;

    ::lives_ok {
       with 'Role::Method';
    } '... composed the method role into the attribute class';

    has 'ghost' => (is => 'ro', default => 'My::Test16::ghost');

    package My::Test17;
    use Moose;

    ::lives_ok {
       with 'Role::Attribute';
    } '... composed the attribute role into the method class';

    sub ghost { 'My::Test17::ghost' }

    package My::Test18;
    use Moose;

    ::lives_ok {
       with 'Role::Attribute';
    } '... composed the attribute role into the attribute class';

    has 'ghost' => (is => 'ro', default => 'My::Test18::ghost');

    package My::Test19;
    use Moose;

    ::lives_ok {
       with 'Role::Method', 'Role::Method2';
    } '... composed method roles into class with method tiebreaker';

    sub ghost { 'My::Test19::ghost' }

    package My::Test20;
    use Moose;

    ::lives_ok {
       with 'Role::Method', 'Role::Method2';
    } '... composed method roles into class with attribute tiebreaker';

    has 'ghost' => (is => 'ro', default => 'My::Test20::ghost');

    package My::Test21;
    use Moose;

    ::lives_ok {
       with 'Role::Attribute', 'Role::Attribute2';
    } '... composed attribute roles into class with method tiebreaker';

    sub ghost { 'My::Test21::ghost' }

    package My::Test22;
    use Moose;

    ::lives_ok {
       with 'Role::Attribute', 'Role::Attribute2';
    } '... composed attribute roles into class with attribute tiebreaker';

    has 'ghost' => (is => 'ro', default => 'My::Test22::ghost');

    package My::Test23;
    use Moose;

    ::lives_ok {
        with 'Role::Method', 'Role::Attribute';
    } '... composed method and attribute role into class with method tiebreaker';

    sub ghost { 'My::Test23::ghost' }

    package My::Test24;
    use Moose;

    ::lives_ok {
        with 'Role::Method', 'Role::Attribute';
    } '... composed method and attribute role into class with attribute tiebreaker';

    has 'ghost' => (is => 'ro', default => 'My::Test24::ghost');

    package My::Test25;
    use Moose;

    ::lives_ok {
        with 'Role::Attribute', 'Role::Method';
    } '... composed attribute and method role into class with method tiebreaker';

    sub ghost { 'My::Test25::ghost' }

    package My::Test26;
    use Moose;

    ::lives_ok {
        with 'Role::Attribute', 'Role::Method';
    } '... composed attribute and method role into class with attribute tiebreaker';

    has 'ghost' => (is => 'ro', default => 'My::Test26::ghost');
}

my $test15 = My::Test15->new;
isa_ok($test15, 'My::Test15');
is($test15->ghost, 'My::Test15::ghost', '... we access the method from the class and ignore the role method');

my $test16 = My::Test16->new;
isa_ok($test16, 'My::Test16');
is($test16->ghost, 'My::Test16::ghost', '... we access the attribute from the class and ignore the role method');

my $test17 = My::Test17->new;
isa_ok($test17, 'My::Test17');
is($test17->ghost, 'My::Test17::ghost', '... we access the method from the class and ignore the role attribute');

my $test18 = My::Test18->new;
isa_ok($test18, 'My::Test18');
is($test18->ghost, 'My::Test18::ghost', '... we access the attribute from the class and ignore the role attribute');

my $test19 = My::Test19->new;
isa_ok($test19, 'My::Test19');
is($test19->ghost, 'My::Test19::ghost', '... we access the method from the class and ignore the role methods');

my $test20 = My::Test20->new;
isa_ok($test20, 'My::Test20');
is($test20->ghost, 'My::Test20::ghost', '... we access the attribute from the class and ignore the role methods');

my $test21 = My::Test21->new;
isa_ok($test21, 'My::Test21');
is($test21->ghost, 'My::Test21::ghost', '... we access the method from the class and ignore the role attributes');

my $test22 = My::Test22->new;
isa_ok($test22, 'My::Test22');
is($test22->ghost, 'My::Test22::ghost', '... we access the attribute from the class and ignore the role attributes');

my $test23 = My::Test23->new;
isa_ok($test23, 'My::Test23');
is($test23->ghost, 'My::Test23::ghost', '... we access the method from the class and ignore the role method and attribute');

my $test24 = My::Test24->new;
isa_ok($test24, 'My::Test24');
is($test24->ghost, 'My::Test24::ghost', '... we access the attribute from the class and ignore the role method and attribute');

my $test25 = My::Test25->new;
isa_ok($test25, 'My::Test25');
is($test25->ghost, 'My::Test25::ghost', '... we access the method from the class and ignore the role attribute and method');

my $test26 = My::Test26->new;
isa_ok($test26, 'My::Test26');
is($test26->ghost, 'My::Test26::ghost', '... we access the attribute from the class and ignore the role attribute and method');

=cut

done_testing;
