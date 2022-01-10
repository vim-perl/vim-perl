#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Animal;
    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'Natural' => as 'Int' => where { $_ > 0 } =>
        message {"This number ($_) is not a positive integer!"};

    subtype 'NaturalLessThanTen' => as 'Natural' => where { $_ < 10 } =>
        message {"This number ($_) is not less than ten!"};

    has leg_count => (
        is      => 'rw',
        isa     => 'NaturalLessThanTen',
        lazy    => 1,
        default => 0,
    );
}

is( exception { my $goat = Animal->new( leg_count => 4 ) }, undef, '... no errors thrown, value is good' );
is( exception { my $spider = Animal->new( leg_count => 8 ) }, undef, '... no errors thrown, value is good' );

like( exception { my $fern = Animal->new( leg_count => 0 ) }, qr/This number \(0\) is not less than ten!/, 'gave custom supertype error message on new' );

like( exception { my $centipede = Animal->new( leg_count => 30 ) }, qr/This number \(30\) is not less than ten!/, 'gave custom subtype error message on new' );

my $chimera;
is( exception { $chimera = Animal->new( leg_count => 4 ) }, undef, '... no errors thrown, value is good' );

like( exception { $chimera->leg_count(0) }, qr/This number \(0\) is not less than ten!/, 'gave custom supertype error message on set to 0' );

like( exception { $chimera->leg_count(16) }, qr/This number \(16\) is not less than ten!/, 'gave custom subtype error message on set to 16' );

my $gimp = eval { Animal->new() };
is( $@, '', '... no errors thrown, value is good' );

like( exception { $gimp->leg_count }, qr/This number \(0\) is not less than ten!/, 'gave custom supertype error message on lazy set to 0' );

done_testing;
