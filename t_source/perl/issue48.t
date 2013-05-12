# vim:ft=perl

use strict;
use warnings;

print @{ $dbh->selectrow_arrayref(<<SQL) };
SELECT s[site_hum_id
  FROM site_inst s
SQL

print %{ $dbh->selectrow_arrayref(<<SQL) };
SELECT s[site_hum_id
  FROM site_inst s
SQL

*{"foo\::bar"} = 1;

print 'hi';
