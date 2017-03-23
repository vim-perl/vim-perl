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

my $extras   = _extra_options();
is $extras, undef, 'no extra options for filters yet';

my $properties = {
    indent => 5,
    _current_indent => 0,
    _linebreak => \"\n",
};

sub test {
    is scalar @_, 2, 'got two elements';
    is $_[0], 'SCALAR', 'first element';
    is_deeply $_[1], $properties, 'second element is properties';

    return 'test';
}

filter 'SCALAR', sub { return 'test' }, { show_repeated => 1 };

$filters = _filter_list();
$extras  = _extra_options();

ok exists $filters->{SCALAR}, 'SCALAR filter set';
is scalar @{ $filters->{SCALAR} }, 1, 'two scalar filters';

ok exists $extras->{SCALAR}, 'extras set for SCALAR';
is $extras->{SCALAR}{show_repeated}, 1, 'extra hash ok for SCALAR filter';

is $filters->{SCALAR}->[0]->('SCALAR', $properties), 'test', 'SCALAR filter called';

done_testing;
