#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Test::More;

use_ok('MyMooseA');
use_ok('MyMooseB');

done_testing;
