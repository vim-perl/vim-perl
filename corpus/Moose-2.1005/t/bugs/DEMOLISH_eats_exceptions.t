#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;

use Moose::Util::TypeConstraints;

subtype 'FilePath'
    => as 'Str'
    # This used to try to _really_ check for a valid Unix or Windows
    # path, but the regex wasn't quite right, and all we care about
    # for the tests is that it rejects '/'
    => where { $_ ne '/' };
{
    package Baz;
    use Moose;
    use Moose::Util::TypeConstraints;

    has 'path' => (
        is       => 'ro',
        isa      => 'FilePath',
        required => 1,
    );

    sub BUILD {
        my ( $self, $params ) = @_;
        confess $params->{path} . " does not exist"
            unless -e $params->{path};
    }

    # Defining this causes the FIRST call to Baz->new w/o param to fail,
    # if no call to ANY Moose::Object->new was done before.
    sub DEMOLISH {
        my ( $self ) = @_;
    }
}

{
    package Qee;
    use Moose;
    use Moose::Util::TypeConstraints;

    has 'path' => (
        is       => 'ro',
        isa      => 'FilePath',
        required => 1,
    );

    sub BUILD {
        my ( $self, $params ) = @_;
        confess $params->{path} . " does not exist"
            unless -e $params->{path};
    }

    # Defining this causes the FIRST call to Qee->new w/o param to fail...
    # if no call to ANY Moose::Object->new was done before.
    sub DEMOLISH {
        my ( $self ) = @_;
    }
}

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    has 'path' => (
        is       => 'ro',
        isa      => 'FilePath',
        required => 1,
    );

    sub BUILD {
        my ( $self, $params ) = @_;
        confess $params->{path} . " does not exist"
            unless -e $params->{path};
    }

    # Having no DEMOLISH, everything works as expected...
}

check_em ( 'Baz' );     #     'Baz plain' will fail, aka NO error
check_em ( 'Qee' );     #     ok
check_em ( 'Foo' );     #     ok

check_em ( 'Qee' );     #     'Qee plain' will fail, aka NO error
check_em ( 'Baz' );     #     ok
check_em ( 'Foo' );     #     ok

check_em ( 'Foo' );     #     ok
check_em ( 'Baz' );     #     ok !
check_em ( 'Qee' );     #     ok


sub check_em {
     my ( $pkg ) = @_;
     my ( %param, $obj );

     # Uncomment to see, that it is really any first call.
     # Subsequents calls will not fail, aka giving the correct error.
     {
         local $@;
         my $obj = eval { $pkg->new; };
         ::like( $@, qr/is required/, "... $pkg plain" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new(); };
         ::like( $@, qr/is required/, "... $pkg empty" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new ( notanattr => 1 ); };
         ::like( $@, qr/is required/, "... $pkg undef" );
         ::is( $obj, undef, "... the object is undef" );
     }

     {
         local $@;
         my $obj = eval { $pkg->new ( %param ); };
         ::like( $@, qr/is required/, "... $pkg undef param" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new ( path => '/' ); };
         ::like( $@, qr/does not pass the type constraint/, "... $pkg root path forbidden" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new ( path => '/this_path/does/not_exist' ); };
         ::like( $@, qr/does not exist/, "... $pkg non existing path" );
         ::is( $obj, undef, "... the object is undef" );
     }
     {
         local $@;
         my $obj = eval { $pkg->new ( path => $FindBin::Bin ); };
         ::is( $@, '', "... $pkg no error" );
         ::isa_ok( $obj, $pkg );
         ::isa_ok( $obj, 'Moose::Object' );
         ::is( $obj->path, $FindBin::Bin, "... $pkg got the right value" );
     }
}

done_testing;
