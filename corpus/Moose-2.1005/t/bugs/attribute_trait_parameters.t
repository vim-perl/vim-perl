use strict;
use warnings;
use Test::More;
use Test::Requires {
    'Test::Output' => '0.01', # skip all if not installed
};

{
    package R;
    use Moose::Role;

    sub method { }
}

{
    package C;
    use Moose;

    ::stderr_is{
        has attr => (
            is => 'ro',
            traits => [
                R => { ignored => 1 },
            ],
        );
    } q{}, 'no warning with foreign parameterized attribute traits';

    ::stderr_is{
        has alias_attr => (
            is => 'ro',
            traits => [
                R => { -alias => { method => 'new_name' } },
            ],
        );
    } q{}, 'no warning with -alias parameterized attribute traits';

    ::stderr_is{
        has excludes_attr => (
            is => 'ro',
            traits => [
                R => { -excludes => ['method'] },
            ],
        );
    } q{}, 'no warning with -excludes parameterized attribute traits';
}

done_testing;
