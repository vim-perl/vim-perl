#!/usr/bin/perl

use Test::More;

# for classes ...
{
    package Foo;
    use Moose;

    eval '$foo = 5;';
    ::ok($@, '... got an error because strict is on');
    ::like($@, qr/Global symbol \"\$foo\" requires explicit package name at/, '... got the right error');

    {
        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };

        ::ok(!$warn, '... no warning yet');

        eval 'my $bar = 1 + "hello"';

        ::ok($warn, '... got a warning');
        ::like($warn, qr/Argument \"hello\" isn\'t numeric in addition \(\+\)/, '.. and it is the right warning');
    }
}

# and for roles ...
{
    package Bar;
    use Moose::Role;

    eval '$foo = 5;';
    ::ok($@, '... got an error because strict is on');
    ::like($@, qr/Global symbol \"\$foo\" requires explicit package name at/, '... got the right error');

    {
        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };

        ::ok(!$warn, '... no warning yet');

        eval 'my $bar = 1 + "hello"';

        ::ok($warn, '... got a warning');
        ::like($warn, qr/Argument \"hello\" isn\'t numeric in addition \(\+\)/, '.. and it is the right warning');
    }
}

# and for exporters
{
    package Bar;
    use Moose::Exporter;

    eval '$foo = 5;';
    ::ok($@, '... got an error because strict is on');
    ::like($@, qr/Global symbol \"\$foo\" requires explicit package name at/, '... got the right error');

    {
        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };

        ::ok(!$warn, '... no warning yet');

        eval 'my $bar = 1 + "hello"';

        ::ok($warn, '... got a warning');
        ::like($warn, qr/Argument \"hello\" isn\'t numeric in addition \(\+\)/, '.. and it is the right warning');
    }
}

done_testing;
