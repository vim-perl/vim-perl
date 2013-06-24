#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

sub test_sub {
    my ( $dbh ) = @_;

    my $sql_template = <<'END_SQL';
SELECT {{COLUMNS}} FROM MyTable
END_SQL

    my $sql = $sql_template =~ s/\Q{{COLUMNS}}\E/username/gr;

    return $dbh->selectall_arrayref($sql);
}
