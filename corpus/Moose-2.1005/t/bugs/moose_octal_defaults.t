#!/usr/bin/env perl
use Test::More;

{
    my $package = qq{
package Test::Moose::Go::Boom;
use Moose;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => '019600', # this caused the original failure
);

no Moose;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('quoted 019600 default works');
    my $obj = Test::Moose::Go::Boom->new;
    ::is( $obj->id, '019600', 'value is still the same' );
}

{
    my $package = qq{
package Test::Moose::Go::Boom2;
use Moose;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => 017600,
);

no Moose;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('017600 octal default works');
    my $obj = Test::Moose::Go::Boom2->new;
    ::is( $obj->id, 8064, 'value is still the same' );
}

{
    my $package = qq{
package Test::Moose::Go::Boom3;
use Moose;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => 0xFF,
);

no Moose;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('017600 octal default works');
    my $obj = Test::Moose::Go::Boom3->new;
    ::is( $obj->id, 255, 'value is still the same' );
}

{
    my $package = qq{
package Test::Moose::Go::Boom4;
use Moose;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => '0xFF',
);

no Moose;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('017600 octal default works');
    my $obj = Test::Moose::Go::Boom4->new;
    ::is( $obj->id, '0xFF', 'value is still the same' );
}

{
    my $package = qq{
package Test::Moose::Go::Boom5;
use Moose;
use lib qw(lib);

has id => (
    isa     => 'Str',
    is      => 'ro',
    default => '0 but true',
);

no Moose;

__PACKAGE__->meta->make_immutable;
};

    eval $package;
    $@ ? ::fail($@) : ::pass('017600 octal default works');
    my $obj = Test::Moose::Go::Boom5->new;
    ::is( $obj->id, '0 but true', 'value is still the same' );
}

done_testing;
