#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Test::Requires {
    'IO::String' => '0.01', # skip all if not installed
    'IO::File' => '0.01',
};

{
    package Email::Moose;
    use Moose;
    use Moose::Util::TypeConstraints;

    use IO::String;

    our $VERSION = '0.01';

    # create subtype for IO::String

    subtype 'IO::String'
        => as 'Object'
        => where { $_->isa('IO::String') };

    coerce 'IO::String'
        => from 'Str'
            => via { IO::String->new($_) },
        => from 'ScalarRef',
            => via { IO::String->new($_) };

    # create subtype for IO::File

    subtype 'IO::File'
        => as 'Object'
        => where { $_->isa('IO::File') };

    coerce 'IO::File'
        => from 'FileHandle'
            => via { bless $_, 'IO::File' };

    # create the alias

    subtype 'IO::StringOrFile' => as 'IO::String | IO::File';

    # attributes

    has 'raw_body' => (
        is      => 'rw',
        isa     => 'IO::StringOrFile',
        coerce  => 1,
        default => sub { IO::String->new() },
    );

    sub as_string {
        my ($self) = @_;
        my $fh = $self->raw_body();
        return do { local $/; <$fh> };
    }
}

{
    my $email = Email::Moose->new;
    isa_ok($email, 'Email::Moose');

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, undef, '... got correct empty string');
}

{
    my $email = Email::Moose->new(raw_body => '... this is my body ...');
    isa_ok($email, 'Email::Moose');

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, '... this is my body ...', '... got correct string');

    is( exception {
        $email->raw_body('... this is the next body ...');
    }, undef, '... this will coerce correctly' );

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, '... this is the next body ...', '... got correct string');
}

{
    my $str = '... this is my body (ref) ...';

    my $email = Email::Moose->new(raw_body => \$str);
    isa_ok($email, 'Email::Moose');

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, $str, '... got correct string');

    my $str2 = '... this is the next body (ref) ...';

    is( exception {
        $email->raw_body(\$str2);
    }, undef, '... this will coerce correctly' );

    isa_ok($email->raw_body, 'IO::String');

    is($email->as_string, $str2, '... got correct string');
}

{
    my $io_str = IO::String->new('... this is my body (IO::String) ...');

    my $email = Email::Moose->new(raw_body => $io_str);
    isa_ok($email, 'Email::Moose');

    isa_ok($email->raw_body, 'IO::String');
    is($email->raw_body, $io_str, '... and it is the one we expected');

    is($email->as_string, '... this is my body (IO::String) ...', '... got correct string');

    my $io_str2 = IO::String->new('... this is the next body (IO::String) ...');

    is( exception {
        $email->raw_body($io_str2);
    }, undef, '... this will coerce correctly' );

    isa_ok($email->raw_body, 'IO::String');
    is($email->raw_body, $io_str2, '... and it is the one we expected');

    is($email->as_string, '... this is the next body (IO::String) ...', '... got correct string');
}

{
    my $fh;

    open($fh, '<', $0) || die "Could not open $0";

    my $email = Email::Moose->new(raw_body => $fh);
    isa_ok($email, 'Email::Moose');

    isa_ok($email->raw_body, 'IO::File');

    close($fh);
}

{
    my $fh = IO::File->new($0);

    my $email = Email::Moose->new(raw_body => $fh);
    isa_ok($email, 'Email::Moose');

    isa_ok($email->raw_body, 'IO::File');
    is($email->raw_body, $fh, '... and it is the one we expected');
}

{
    package Foo;

    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'Coerced' => as 'ArrayRef';
    coerce 'Coerced'
        => from 'Value'
        => via { [ $_ ] };

    has carray => (
        is     => 'ro',
        isa    => 'Coerced | Coerced',
        coerce => 1,
    );
}

{
    my $foo;
    is( exception { $foo = Foo->new( carray => 1 ) }, undef, 'Can pass non-ref value for carray' );
    is_deeply(
        $foo->carray, [1],
        'carray was coerced to an array ref'
    );

    like( exception { Foo->new( carray => {} ) }, qr/\QValidation failed for 'Coerced|Coerced' with value \E(?!undef)/, 'Cannot pass a hash ref for carray attribute, and hash ref is not coerced to an undef' );
}

done_testing;
