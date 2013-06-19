#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

sub dump_reasonably_readable_octets {
    my ( $input ) = @_;

    $input =~ s/([^a-zA-Z0-9])/'\x{' . sprintf('%x', ord($1)) . '}'/ge;
    diag($input);
}
