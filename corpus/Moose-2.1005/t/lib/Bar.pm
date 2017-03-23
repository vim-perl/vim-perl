
package Bar;
use Moose;
use Moose::Util::TypeConstraints;

type Baz => where { 1 };

subtype Bling => as Baz => where { 1 };

1;