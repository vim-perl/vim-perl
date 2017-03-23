use strict;
use warnings;

use Test::More;
use Sub::Name 'subname';

BEGIN {
    $^P &= ~0x200; # Don't munge anonymous sub names
}

use Class::MOP;


sub code_name_is {
    my ( $code, $stash, $name ) = @_;

    is_deeply(
        [ Class::MOP::get_code_info($code) ],
        [ $stash, $name ],
        "sub name is ${stash}::$name"
    );
}

code_name_is( sub {}, main => "__ANON__" );

code_name_is( subname("Foo::bar", sub {}), Foo => "bar" );

code_name_is( subname("", sub {}), "main" => "" );

require Class::MOP::Method;
code_name_is( \&Class::MOP::Method::name, "Class::MOP::Method", "name" );

{
    package Foo;

    sub MODIFY_CODE_ATTRIBUTES {
        my ($class, $code) = @_;
        my @info = Class::MOP::get_code_info($code);

        if ( $] >= 5.011 ) {
            ::is_deeply(\@info, ['Foo', 'foo'], "got a name for a code ref in an attr handler");
        }
        else {
            ::is_deeply(\@info, [], "no name for a coderef that's still compiling");
        }
        return ();
    }

    sub foo : Bar {}
}

done_testing;
