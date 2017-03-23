use strict;
use warnings;

use Test::More;
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer {
   alias => 'Dumper',
   filters => {
    'ARRAY' => sub {
       my $ref = shift;
       return join ':', map { Dumper(\$_) } @$ref;
    },
    'HASH' => sub {
        my $ref = shift;
        my %hash = %$ref;
        return Dumper(%hash); # wrong, should fail (needs ref)
    },
   },
};

my @list = (1 .. 3);
is( Dumper(@list), '1:2:3', 'filter with aliased p()' );

eval {
    my %hash = (1 => 2);
    Dumper(%hash);
};
like($@, qr/^\QWhen calling p() without prototypes, please pass arguments as references\E/, 'proper exception');

done_testing;
