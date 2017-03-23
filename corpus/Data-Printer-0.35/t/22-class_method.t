use strict;
use warnings;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

package Foo;
sub new           { bless {}, shift }
sub foo           { return 42    }
sub _data_printer { my $self = shift; return 'foo is ' . $self->foo }

1;

package main;
use Test::More;
use Data::Printer;

my $obj = Foo->new;

is p($obj), 'foo is 42', '_data_printer() called as default class dumper';

is p($obj, class_method => 'foo'), 42, 'class_method overrides default class dumper';

done_testing;
