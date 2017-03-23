#!perl

### MODULES

{
    package PlainMoose;
    use Moose;
    has foo => (is => 'rw');
}
{
    package MooseImmutable;
    use Moose;
    has foo => (is => 'rw');
    __PACKAGE__->meta->make_immutable();
}
{
    package MooseImmutable::NoConstructor;
    use Moose;
    has foo => (is => 'rw');
    __PACKAGE__->meta->make_immutable(inline_constructor => 0);
}
{
    package ClassAccessorFast;
    use warnings;
    use strict;
    use base 'Class::Accessor::Fast';
    __PACKAGE__->mk_accessors(qw(foo));
}

use Benchmark qw(cmpthese);
use Benchmark ':hireswallclock';

my $moose                = PlainMoose->new;
my $moose_immut          = MooseImmutable->new;
my $moose_immut_no_const = MooseImmutable::NoConstructor->new;
my $caf                  = ClassAccessorFast->new;

my $acc_rounds = 100_000;
my $ins_rounds = 100_000;

print "\nSETTING\n";
cmpthese($acc_rounds, {
    Moose                       => sub { $moose->foo(23) },
    MooseImmutable              => sub { $moose_immut->foo(23) },
    MooseImmutableNoConstructor => sub { $moose_immut_no_const->foo(23) },
    ClassAccessorFast           => sub { $caf->foo(23) },
}, 'noc');

print "\nGETTING\n";
cmpthese($acc_rounds, {
    Moose                       => sub { $moose->foo },
    MooseImmutable              => sub { $moose_immut->foo },
    MooseImmutableNoConstructor => sub { $moose_immut_no_const->foo },
    ClassAccessorFast           => sub { $caf->foo },
}, 'noc');

my (@moose, @moose_immut, @moose_immut_no_const, @caf_stall);
print "\nCREATION\n";
cmpthese($ins_rounds, {
    Moose                       => sub { push @moose, PlainMoose->new(foo => 23) },
    MooseImmutable              => sub { push @moose_immut, MooseImmutable->new(foo => 23) },
    MooseImmutableNoConstructor => sub { push @moose_immut_no_const, MooseImmutable::NoConstructor->new(foo => 23) },
    ClassAccessorFast           => sub { push @caf_stall, ClassAccessorFast->new({foo => 23}) },
}, 'noc');

my ( $moose_idx, $moose_immut_idx, $moose_immut_no_const_idx, $caf_idx ) = ( 0, 0, 0, 0 );
print "\nDESTRUCTION\n";
cmpthese($ins_rounds, {
    Moose => sub {
        $moose[$moose_idx] = undef;
        $moose_idx++;
    },
    MooseImmutable => sub {
        $moose_immut[$moose_immut_idx] = undef;
        $moose_immut_idx++;
    },
    MooseImmutableNoConstructor => sub {
        $moose_immut_no_const[$moose_immut_no_const_idx] = undef;
        $moose_immut_no_const_idx++;
    },
    ClassAccessorFast   => sub {
        $caf_stall[$caf_idx] = undef;
        $caf_idx++;
    },
}, 'noc');


