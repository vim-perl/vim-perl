use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Meta::TypeConstraint;
use Moose::Util::TypeConstraints;


TODO:
{
    local $TODO = 'type names are not validated in the TC metaclass';

    # Test written in this way to avoid a warning from like(undef, qr...);
    # -- rjbs, 2010-10-25
    my $error = exception {
        Moose::Meta::TypeConstraint->new( name => 'Foo-Bar' )
    };

    if (defined $error) {
        like(
            $error,
            qr/contains invalid characters/,
            'Type names cannot contain a dash',
        );
    } else {
        fail("Type names cannot contain a dash");
    }
}

is( exception { Moose::Meta::TypeConstraint->new( name => 'Foo.Bar::Baz' ) }, undef, 'Type names can contain periods and colons' );

like( exception { subtype 'Foo-Baz' => as 'Item' }, qr/contains invalid characters/, 'Type names cannot contain a dash (via subtype sugar)' );

is( exception { subtype 'Foo.Bar::Baz' => as 'Item' }, undef, 'Type names can contain periods and colons (via subtype sugar)' );

is( Moose::Util::TypeConstraints::find_or_parse_type_constraint('ArrayRef[In-valid]'),
    undef,
    'find_or_parse_type_constraint returns undef on an invalid name' );

is( Moose::Util::TypeConstraints::find_or_parse_type_constraint('ArrayRef[Va.lid]'),
    'ArrayRef[Va.lid]',
    'find_or_parse_type_constraint returns name for valid name' );

done_testing;
