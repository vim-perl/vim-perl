use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer::Filter;

my $filters = _filter_list();
is $filters, undef, 'no filters set';

my $properties = {
    indent => 5,
    _current_indent => 0,
    _linebreak => \"\n",
};

sub test {
    is scalar @_, 2, 'got two elements';
    is $_[0], 'SCALAR', 'first element';
    is_deeply $_[1], $properties, 'second element is properties';

    indent();
    is $_[1]->{_current_indent}, 5, 'indent()';
    is newline, "\n     ", 'newline()';
    indent();
    is $_[1]->{_current_indent}, 10, 'indent() again';
    outdent;
    is $_[1]->{_current_indent}, 5, 'outdent()';

    return 'test';
}

sub test2 { 'other test for: ' . p($_[0], $_[1]) }

filter 'SCALAR', \&test;
filter 'SCALAR', \&test2;

filter HASH => \&test2;

$filters = _filter_list();
is scalar keys %$filters, 2, 'filters set';

ok exists $filters->{SCALAR}, 'SCALAR filter set';
ok exists $filters->{HASH}, 'HASH filter set';

is scalar @{ $filters->{SCALAR} }, 2, 'two scalar filters';
is scalar @{ $filters->{HASH}   }, 1, 'only one hash filter';

is $filters->{SCALAR}->[1]->('SCALAR', $properties), 'test', 'SCALAR filter called';
is $filters->{SCALAR}->[0]->('SCALAR', $properties), 'other test for: "SCALAR"', 'SCALAR filter called again';

is $filters->{HASH}->[0]->('HASH', $properties), 'other test for: "HASH"', 'HASH filter with p()';

done_testing;
