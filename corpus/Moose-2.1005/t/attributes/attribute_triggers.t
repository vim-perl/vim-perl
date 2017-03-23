#!/usr/bin/perl

use strict;
use warnings;

use Scalar::Util 'isweak';

use Test::More;
use Test::Fatal;


{
    package Foo;
    use Moose;

    has 'bar' => (is      => 'rw',
                  isa     => 'Maybe[Bar]',
                  trigger => sub {
                      my ($self, $bar) = @_;
                      $bar->foo($self) if defined $bar;
                  });

    has 'baz' => (writer => 'set_baz',
                  reader => 'get_baz',
                  isa    => 'Baz',
                  trigger => sub {
                      my ($self, $baz) = @_;
                      $baz->foo($self);
                  });


    package Bar;
    use Moose;

    has 'foo' => (is => 'rw', isa => 'Foo', weak_ref => 1);

    package Baz;
    use Moose;

    has 'foo' => (is => 'rw', isa => 'Foo', weak_ref => 1);
}

{
    my $foo = Foo->new;
    isa_ok($foo, 'Foo');

    my $bar = Bar->new;
    isa_ok($bar, 'Bar');

    my $baz = Baz->new;
    isa_ok($baz, 'Baz');

    is( exception {
        $foo->bar($bar);
    }, undef, '... did not die setting bar' );

    is($foo->bar, $bar, '... set the value foo.bar correctly');
    is($bar->foo, $foo, '... which in turn set the value bar.foo correctly');

    ok(isweak($bar->{foo}), '... bar.foo is a weak reference');

    is( exception {
        $foo->bar(undef);
    }, undef, '... did not die un-setting bar' );

    is($foo->bar, undef, '... set the value foo.bar correctly');
    is($bar->foo, $foo, '... which in turn set the value bar.foo correctly');

    # test the writer

    is( exception {
        $foo->set_baz($baz);
    }, undef, '... did not die setting baz' );

    is($foo->get_baz, $baz, '... set the value foo.baz correctly');
    is($baz->foo, $foo, '... which in turn set the value baz.foo correctly');

    ok(isweak($baz->{foo}), '... baz.foo is a weak reference');
}

{
    my $bar = Bar->new;
    isa_ok($bar, 'Bar');

    my $baz = Baz->new;
    isa_ok($baz, 'Baz');

    my $foo = Foo->new(bar => $bar, baz => $baz);
    isa_ok($foo, 'Foo');

    is($foo->bar, $bar, '... set the value foo.bar correctly');
    is($bar->foo, $foo, '... which in turn set the value bar.foo correctly');

    ok(isweak($bar->{foo}), '... bar.foo is a weak reference');

    is($foo->get_baz, $baz, '... set the value foo.baz correctly');
    is($baz->foo, $foo, '... which in turn set the value baz.foo correctly');

    ok(isweak($baz->{foo}), '... baz.foo is a weak reference');
}

# some errors

{
    package Bling;
    use Moose;

    ::isnt( ::exception {
        has('bling' => (is => 'rw', trigger => 'Fail'));
    }, undef, '... a trigger must be a CODE ref' );

    ::isnt( ::exception {
        has('bling' => (is => 'rw', trigger => []));
    }, undef, '... a trigger must be a CODE ref' );
}

# Triggers do not fire on built values

{
    package Blarg;
    use Moose;

    our %trigger_calls;
    our %trigger_vals;
    has foo => (is => 'rw', default => sub { 'default foo value' },
                trigger => sub { my ($self, $val, $attr) = @_;
                                 $trigger_calls{foo}++;
                                 $trigger_vals{foo} = $val });
    has bar => (is => 'rw', lazy_build => 1,
                trigger => sub { my ($self, $val, $attr) = @_;
                                 $trigger_calls{bar}++;
                                 $trigger_vals{bar} = $val });
    sub _build_bar { return 'default bar value' }
    has baz => (is => 'rw', builder => '_build_baz',
                trigger => sub { my ($self, $val, $attr) = @_;
                                 $trigger_calls{baz}++;
                                 $trigger_vals{baz} = $val });
    sub _build_baz { return 'default baz value' }
}

{
    my $blarg;
    is( exception { $blarg = Blarg->new; }, undef, 'Blarg->new() lives' );
    ok($blarg, 'Have a $blarg');
    foreach my $attr (qw/foo bar baz/) {
        is($blarg->$attr(), "default $attr value", "$attr has default value");
    }
    is_deeply(\%Blarg::trigger_calls, {}, 'No triggers fired');
    foreach my $attr (qw/foo bar baz/) {
        $blarg->$attr("Different $attr value");
    }
    is_deeply(\%Blarg::trigger_calls, { map { $_ => 1 } qw/foo bar baz/ }, 'All triggers fired once on assign');
    is_deeply(\%Blarg::trigger_vals, { map { $_ => "Different $_ value" } qw/foo bar baz/ }, 'All triggers given assigned values');

    is( exception { $blarg => Blarg->new( map { $_ => "Yet another $_ value" } qw/foo bar baz/ ) }, undef, '->new() with parameters' );
    is_deeply(\%Blarg::trigger_calls, { map { $_ => 2 } qw/foo bar baz/ }, 'All triggers fired once on construct');
    is_deeply(\%Blarg::trigger_vals, { map { $_ => "Yet another $_ value" } qw/foo bar baz/ }, 'All triggers given assigned values');
}

# Triggers do not receive the meta-attribute as an argument, but do
# receive the old value

{
    package Foo;
    use Moose;
    our @calls;
    has foo => (is => 'rw', trigger => sub { push @calls, [@_] });
}

{
    my $attr = Foo->meta->get_attribute('foo');

    my $foo = Foo->new;
    $attr->set_value( $foo, 2 );

    is_deeply(
        \@Foo::calls,
        [ [ $foo, 2 ] ],
        'trigger called correctly on initial set via meta-API',
    );
    @Foo::calls = ();

    $attr->set_value( $foo, 3 );

    is_deeply(
        \@Foo::calls,
        [ [ $foo, 3, 2 ] ],
        'trigger called correctly on second set via meta-API',
    );
    @Foo::calls = ();

    $attr->set_raw_value( $foo, 4 );

    is_deeply(
        \@Foo::calls,
        [ ],
        'trigger not called using set_raw_value method',
    );
    @Foo::calls = ();
}

{
    my $foo = Foo->new(foo => 2);
    is_deeply(
        \@Foo::calls,
        [ [ $foo, 2 ] ],
        'trigger called correctly on construction',
    );
    @Foo::calls = ();

    $foo->foo(3);
    is_deeply(
        \@Foo::calls,
        [ [ $foo, 3, 2 ] ],
        'trigger called correctly on set (with old value)',
    );
    @Foo::calls = ();
    Foo->meta->make_immutable, redo if Foo->meta->is_mutable;
}

done_testing;
