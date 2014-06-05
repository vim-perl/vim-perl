#!/usr/bin/env perl

use strict;
use warnings;
use feature 'postderef';

$sref->$*;
$aref->@*;
$href->%*;
$cref->&*;
$gref->**;

$aref->@[1];
$href->@{1};
$aref->%[1];
$href->%{1};
