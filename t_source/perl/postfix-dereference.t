#!/usr/bin/env perl

use strict;
use warnings;
use feature 'postderef';

$sref->$*; # comment
$aref->@*; # comment
$href->%*; # comment
$cref->&*; # comment
$gref->**; # comment

$aref->@[1]; # comment
$href->@{1}; # comment
$aref->%[1]; # comment
$href->%{1}; # comment
