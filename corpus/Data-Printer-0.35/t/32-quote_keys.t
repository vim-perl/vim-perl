use strict;
use warnings;
use Test::More;

BEGIN {
    delete $ENV{ANSI_COLORS_DISABLED};
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
    use_ok ('Term::ANSIColor');
    use_ok (
        'Data::Printer', colored => 0,
    );
};

my %hash = (
        '' => 1,
        a  => 1,
);

is(
   p(%hash),
   "{
    ''   1,
    a    1
}",
    'auto quote_keys (implicit)'
);

is(
   p(%hash, quote_keys => 'auto'),
   "{
    ''   1,
    a    1
}",
    'auto quote_keys (explicit)'
);

is(
   p(%hash, quote_keys => 1),
   "{
    ''    1,
    'a'   1
}",
    'quote_keys active'
);

is(
   p(%hash, quote_keys => 0),
   "{
        1,
    a   1
}",
    'quote_keys inactive'
);

done_testing;
