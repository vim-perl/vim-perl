use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;

plan skip_all => 'set TEST_POD to enable this test (developer only!)'
  unless $ENV{TEST_POD};

all_pod_coverage_ok({
  also_private => [ qr/^(?:ARRAY|CODE|GLOB|HASH|REF|VSTRING|Regexp|FORMAT|LVALUE)$/, qr/^np$/ ],
});
