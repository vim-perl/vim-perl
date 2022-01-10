use strict;
use warnings;
use Test::More;
use Class::MOP;

do {
    package Without::Overloading;
    sub new { bless {}, shift }

    package With::Overloading;
    use base 'Without::Overloading';
    use overload q{""} => sub { "overloaded" };
};

my $without = bless {}, "Without::Overloading";
like("$without", qr/^Without::Overloading/, "no overloading");

my $with = With::Overloading->new;
is("$with", "overloaded", "initial overloading works");


my $meta = Class::MOP::Class->initialize('With::Overloading');

$meta->rebless_instance($without);
is("$without", "overloaded", "overloading after reblessing works");

done_testing;
