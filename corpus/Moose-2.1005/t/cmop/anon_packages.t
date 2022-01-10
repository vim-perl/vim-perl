#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Class::MOP;

{
    my $name;
    {
        my $anon = Class::MOP::Package->create_anon;
        $name = $anon->name;
        $anon->add_package_symbol('&foo' => sub {});
        can_ok($name, 'foo');
        ok($anon->is_anon, "is anon");
    }

    ok(!$name->can('foo'), "!$name->can('foo')");
}

{
    my $name;
    {
        my $anon = Class::MOP::Package->create_anon(weaken => 0);
        $name = $anon->name;
        $anon->add_package_symbol('&foo' => sub {});
        can_ok($name, 'foo');
        ok($anon->is_anon, "is anon");
    }

    can_ok($name, 'foo');
}

{
    like(exception { Class::MOP::Package->create_anon(cache => 1) },
         qr/^Packages are not cacheable/,
         "can't cache anon packages");
}

done_testing;
