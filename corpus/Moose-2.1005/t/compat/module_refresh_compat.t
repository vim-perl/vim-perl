#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More;
use Test::Fatal;

use File::Spec;
use File::Temp 'tempdir';

use Test::Requires {
    'Module::Refresh' => '0.01', # skip all if not installed
};

=pod

First lets test some of our simple example modules ...

=cut

my @modules = qw[Foo Bar MyMooseA MyMooseB MyMooseObject];

do {
    use_ok($_);

    is($_->meta->name, $_, '... initialized the meta correctly');

    is( exception {
        Module::Refresh->new->refresh_module($_ . '.pm')
    }, undef, '... successfully refreshed ' );
} foreach @modules;

=pod

Now, lets try something a little trickier
and actually change the module itself.

=cut

my $dir = tempdir( "MooseTest-XXXXX", CLEANUP => 1, TMPDIR => 1 );
push @INC, $dir;

my $test_module_file = File::Spec->catdir($dir, 'TestBaz.pm');

my $test_module_source_1 = q|
package TestBaz;
use Moose;
has 'foo' => (is => 'ro', isa => 'Int');
1;
|;

my $test_module_source_2 = q|
package TestBaz;
use Moose;
extends 'Foo';
has 'foo' => (is => 'rw', isa => 'Int');
1;
|;

{
    open FILE, ">", $test_module_file
        || die "Could not open $test_module_file because $!";
    print FILE $test_module_source_1;
    close FILE;
}

use_ok('TestBaz');
is(TestBaz->meta->name, 'TestBaz', '... initialized the meta correctly');
ok(TestBaz->meta->has_attribute('foo'), '... it has the foo attribute as well');
ok(!TestBaz->isa('Foo'), '... TestBaz is not a Foo');

{
    open FILE, ">", $test_module_file
        || die "Could not open $test_module_file because $!";
    print FILE $test_module_source_2;
    close FILE;
}

is( exception {
    Module::Refresh->new->refresh_module('TestBaz.pm')
}, undef, '... successfully refreshed ' );

is(TestBaz->meta->name, 'TestBaz', '... initialized the meta correctly');
ok(TestBaz->meta->has_attribute('foo'), '... it has the foo attribute as well');
ok(TestBaz->isa('Foo'), '... TestBaz is a Foo');

unlink $test_module_file;

done_testing;
