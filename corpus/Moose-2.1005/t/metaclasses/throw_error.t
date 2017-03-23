#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

{

    package Foo;
    use Moose;

    has foo => ( is => "ro" );

    package Bar;
    use metaclass (
        metaclass   => "Moose::Meta::Class",
        error_class => "Moose::Error::Croak",
    );
    use Moose;

    has foo => ( is => "ro" );

    BEGIN {
        package Baz::Error;
        use Moose;
        extends 'Moose::Object', 'Moose::Error::Default';

        has message    => ( isa => "Str",                    is => "ro" );
        has attr       => ( isa => "Moose::Meta::Attribute", is => "ro" );
        has method     => ( isa => "Moose::Meta::Method",    is => "ro" );
        has metaclass  => ( isa => "Moose::Meta::Class",     is => "ro" );
        has data       => ( is  => "ro" );
        has line       => ( isa => "Int",                    is => "ro" );
        has file       => ( isa => "Str",                    is => "ro" );
        has last_error => ( isa => "Any",                    is => "ro" );
    }

    package Baz;
    use metaclass (
        metaclass   => "Moose::Meta::Class",
        error_class => "Baz::Error",
    );
    use Moose;

    has foo => ( is => "ro" );
}

my $line;
sub blah { $line = __LINE__; shift->foo(4) }

sub create_error {
    eval {
        eval { die "Blah" };
        blah(shift);
    };
    ok( my $e = $@, "got some error" );
    return {
        file  => __FILE__,
        line  => $line,
        error => $e,
    };
}

with_immutable {
{
    my $e = create_error( Foo->new );
    ok( !ref( $e->{error} ), "error is a string" );
    like( $e->{error}, qr/line $e->{line}\n.*\n/s, "confess" );
}

{
    my $e = create_error( Bar->new );
    ok( !ref( $e->{error} ), "error is a string" );
    like( $e->{error}, qr/line $e->{line}\.?$/s, "croak" );
}

{
    my $e = create_error( my $baz = Baz->new );
    isa_ok( $e->{error}, "Baz::Error" );
    unlike( $e->{error}->message, qr/line $e->{line}/s,
        "no line info, just a message" );
    isa_ok( $e->{error}->metaclass, "Moose::Meta::Class", "metaclass" );
    is( $e->{error}->metaclass, Baz->meta, "metaclass value" );
    isa_ok( $e->{error}->attr, "Moose::Meta::Attribute", "attr" );
    is( $e->{error}->attr, Baz->meta->get_attribute("foo"), "attr value" );
    isa_ok( $e->{error}->method, "Moose::Meta::Method", "method" );
    is( $e->{error}->method, Baz->meta->get_method("foo"), "method value" );
    is( $e->{error}->line,   $e->{line},                   "line attr" );
    is( $e->{error}->file,   $e->{file},                   "file attr" );
    is_deeply( $e->{error}->data, [ $baz, 4 ], "captured args" );
    like( $e->{error}->last_error, qr/Blah/, "last error preserved" );
}
} 'Foo', 'Bar', 'Baz';

{
    package Role::Foo;
    use Moose::Role;

    sub foo { }
}

{
    package Baz::Sub;

    use Moose;
    extends 'Baz';

    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => { class => ['Role::Foo'] },
    );
}

{
    package Baz::Sub::Sub;
    use metaclass (
        metaclass   => 'Moose::Meta::Class',
        error_class => 'Moose::Error::Croak',
    );
    use Moose;

    ::isnt( ::exception { extends 'Baz::Sub' }, undef, 'error_class is included in metaclass compatibility checks' );
}

{
    package Foo::Sub;

    use metaclass (
        metaclass   => 'Moose::Meta::Class',
        error_class => 'Moose::Error::Croak',
    );

    use Moose;

    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => { class => ['Role::Foo'] },
    );
}

ok( Foo::Sub->meta->error_class->isa('Moose::Error::Croak'),
    q{Foo::Sub's error_class still isa Moose::Error::Croak} );

{
    package Foo::Sub::Sub;
    use Moose;

    ::is( ::exception { extends 'Foo::Sub' }, undef, 'error_class differs by role so incompat is handled' );

    Moose::Util::MetaRole::apply_metaroles(
        for             => __PACKAGE__,
        class_metaroles => { error => ['Role::Foo'] },
    );
}

ok( Foo::Sub::Sub->meta->error_class->meta->does_role('Role::Foo'),
    q{Foo::Sub::Sub's error_class does Role::Foo} );
ok( Foo::Sub::Sub->meta->error_class->isa('Moose::Error::Croak'),
    q{Foo::Sub::Sub's error_class now subclasses Moose::Error::Croak} );

{
    package Quux::Default;
    use Moose;

    has foo => (is => 'ro');
    sub bar { shift->foo(1) }
}

{
    package Quux::Croak;
    use metaclass 'Moose::Meta::Class', error_class => 'Moose::Error::Croak';
    use Moose;

    has foo => (is => 'ro');
    sub bar { shift->foo(1) }
}

{
    package Quux::Confess;
    use metaclass 'Moose::Meta::Class', error_class => 'Moose::Error::Confess';
    use Moose;

    has foo => (is => 'ro');
    sub bar { shift->foo(1) }
}

sub stacktrace_ok (&) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $code = shift;
    eval { $code->() };
    my @lines = split /\n/, $@;
    cmp_ok(scalar(@lines), '>', 1, "got a stacktrace");
}

sub stacktrace_not_ok (&) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $code = shift;
    eval { $code->() };
    my @lines = split /\n/, $@;
    cmp_ok(scalar(@lines), '==', 1, "didn't get a stacktrace");
}

with_immutable {
my $default = Quux::Default->new;
my $croak = Quux::Croak->new;
my $confess = Quux::Confess->new;

is($default->meta->error_class, 'Moose::Error::Default');
is($croak->meta->error_class, 'Moose::Error::Croak');
is($confess->meta->error_class, 'Moose::Error::Confess');

{
    local $ENV{MOOSE_ERROR_STYLE};
    stacktrace_ok { $default->bar };
    stacktrace_not_ok { $croak->bar };
    stacktrace_ok { $confess->bar };
}

{
    local $ENV{MOOSE_ERROR_STYLE} = 'croak';
    stacktrace_not_ok { $default->bar };
    stacktrace_not_ok { $croak->bar };
    stacktrace_ok { $confess->bar };
}

{
    local $ENV{MOOSE_ERROR_STYLE} = 'confess';
    stacktrace_ok { $default->bar };
    stacktrace_not_ok { $croak->bar };
    stacktrace_ok { $confess->bar };
}
} 'Quux::Default', 'Quux::Croak', 'Quux::Confess';

done_testing;
