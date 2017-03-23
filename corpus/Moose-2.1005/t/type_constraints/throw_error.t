use strict;
use warnings;

use Test::More;

use Moose::Util::TypeConstraints;


eval { Moose::Util::TypeConstraints::create_type_constraint_union() };

like( $@, qr/\QYou must pass in at least 2 type names to make a union/,
      'can throw a proper error without Moose being loaded by the caller' );

done_testing;
