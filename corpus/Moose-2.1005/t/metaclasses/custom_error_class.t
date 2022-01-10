use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Output' => '0.01',
};

{
    package My::Exception;

    use Moose;

    has error => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has [qw( line file package )] => (
        is       => 'ro',
        required => 1,
    );

    sub throw {
        my ($self) = @_;
        die $self;
    }
}

{
    package My::Error;

    use base qw( Moose::Error::Default );

    sub new {
        my ( $self, @args ) = @_;

        $self->create_error_exception(@args)->throw;
    }

    sub create_error_exception {
        my ( $self, %params ) = @_;

        my $exception = My::Exception->new(
            error   => $params{message},
            line    => $params{line},
            file    => $params{file},
            package => $params{pack},
        );

        return $exception;
    }
}

{
    package My::Class;

    use Moose;

    __PACKAGE__->meta->error_class("My::Error");

    has 'test1' => (
        is       => 'rw',
        required => 1,
    );

    ::stderr_is(
        sub { __PACKAGE__->meta->make_immutable },
        q{},
        'no warnings when calling make_immutable with a custom error class'
    );
}

{
    package My::ClassMutable;

    use Moose;

    __PACKAGE__->meta->error_class("My::Error");

    has 'test1' => (
        is       => 'rw',
        required => 1,
    );
}

{
    eval {
        package My::Test;
# line 42
        My::Class->new;
    };
    my $error = $@;

    isa_ok(
        $error, 'My::Exception',
        'got exception object (immutable class)'
    );
    is(
        $error->error, 'Attribute (test1) is required',
        'got the right message (immutable class)'
    );
    is(
        $error->package, 'My::Test',
        'got the right package (immutable class)'
    );
    is( $error->line, 42, 'got the right line (immutable class)' );
}

{
    eval {
        package My::TestMutable;
# line 42
        My::ClassMutable->new;
    };
    my $error = $@;

    isa_ok( $error, 'My::Exception', 'got exception object (mutable class)' );
    is(
        $error->error, 'Attribute (test1) is required',
        'got the right message (mutable class)'
    );
}

done_testing;
