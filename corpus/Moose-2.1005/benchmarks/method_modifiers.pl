#!perl

### MODULES

{
    package PlainParent;
    sub new { bless {} => shift }
    sub method { "P" }
}
{
    package MooseParent;
    use Moose;
    sub method { "P" }
}

{
    package CMMChild::Before;
    use Class::Method::Modifiers;
    use base 'PlainParent';

    before method => sub { "B" };
}
{
    package MooseBefore;
    use Moose;
    extends 'MooseParent';

    before method => sub { "B" };
}

{
    package CMMChild::Around;
    use Class::Method::Modifiers;
    use base 'PlainParent';

    around method => sub { shift->() . "A" };
}
{
    package MooseAround;
    use Moose;
    extends 'MooseParent';

    around method => sub { shift->() . "A" };
}

{
    package CMMChild::AllThree;
    use Class::Method::Modifiers;
    use base 'PlainParent';

    before method => sub { "B" };
    around method => sub { shift->() . "A" };
    after  method => sub { "Z" };
}
{
    package MooseAllThree;
    use Moose;
    extends 'MooseParent';

    before method => sub { "B" };
    around method => sub { shift->() . "A" };
    after  method => sub { "Z" };
}
{
    package CMM::Install;
    use Class::Method::Modifiers;
    use base 'PlainParent';
}
{
    package Moose::Install;
    use Moose;
    extends 'MooseParent';
}

use Benchmark qw(cmpthese);
use Benchmark ':hireswallclock';

my $rounds = -5;

my $cmm_before   = CMMChild::Before->new();
my $cmm_around   = CMMChild::Around->new();
my $cmm_allthree = CMMChild::AllThree->new();

my $moose_before   = MooseBefore->new();
my $moose_around   = MooseAround->new();
my $moose_allthree = MooseAllThree->new();

print "\nBEFORE\n";
cmpthese($rounds, {
    Moose                       => sub { $moose_before->method() },
    ClassMethodModifiers        => sub { $cmm_before->method() },
}, 'noc');

print "\nAROUND\n";
cmpthese($rounds, {
    Moose                       => sub { $moose_around->method() },
    ClassMethodModifiers        => sub { $cmm_around->method() },
}, 'noc');

print "\nALL THREE\n";
cmpthese($rounds, {
    Moose                       => sub { $moose_allthree->method() },
    ClassMethodModifiers        => sub { $cmm_allthree->method() },
}, 'noc');

print "\nINSTALL AROUND\n";
cmpthese($rounds, {
    Moose                       => sub {
        package Moose::Install;
        Moose::Install::around(method => sub {});
    },
    ClassMethodModifiers        => sub {
        package CMM::Install;
        CMM::Install::around(method => sub {});
    },
}, 'noc');

