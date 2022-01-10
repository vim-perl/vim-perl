#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package Attribute::Trait::Awesome;
    use Moose::Role;
}

BEGIN {
    package Awesome::Exporter;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        trait_aliases => ['Attribute::Trait::Awesome'],
    );
}

{
    package Awesome;
    use Moose;
    BEGIN { Awesome::Exporter->import }

    has foo => (
        traits => [Awesome],
        is     => 'ro',
    );
    ::does_ok(__PACKAGE__->meta->get_attribute('foo'), 'Attribute::Trait::Awesome');

    no Moose;
    BEGIN { Awesome::Exporter->unimport }

    my $val = eval "Awesome";
    ::like($@, qr/Bareword "Awesome" not allowed/, "unimported properly");
    ::is($val, undef, "unimported properly");
}

BEGIN {
    package Awesome2::Exporter;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        trait_aliases => [
            [ 'Attribute::Trait::Awesome' => 'Awesome2' ],
        ],
    );
}

{
    package Awesome2;
    use Moose;
    BEGIN { Awesome2::Exporter->import }

    has foo => (
        traits => [Awesome2],
        is     => 'ro',
    );
    ::does_ok(__PACKAGE__->meta->get_attribute('foo'), 'Attribute::Trait::Awesome');

    BEGIN { Awesome2::Exporter->unimport }

    my $val = eval "Awesome2";
    ::like($@, qr/Bareword "Awesome2" not allowed/, "unimported properly");
    ::is($val, undef, "unimported properly");
}

{
    package Awesome2::Rename;
    use Moose;
    BEGIN { Awesome2::Exporter->import(Awesome2 => { -as => 'emosewA' }) }

    has foo => (
        traits => [emosewA],
        is     => 'ro',
    );
    ::does_ok(__PACKAGE__->meta->get_attribute('foo'), 'Attribute::Trait::Awesome');

    BEGIN { Awesome2::Exporter->unimport }

    { our $TODO; local $TODO = "unimporting renamed subs currently doesn't work";
    my $val = eval "emosewA";
    ::like($@, qr/Bareword "emosewA" not allowed/, "unimported properly");
    ::is($val, undef, "unimported properly");
    }
}

done_testing;
