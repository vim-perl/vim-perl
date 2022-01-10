use strict;
use warnings;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

package Tie::Fighter::Scalar;

sub TIESCALAR {
    my $class = shift;
    my $foo = 1;
    return bless \$foo, $class;
}

sub FETCH {
    my $self = shift;
    return $$self;
}

sub STORE { }

package Tie::Fighter::Array;

sub TIEARRAY {
    my $class = shift;
    my @foo = (2, 3);
    return bless \@foo, $class;
}

sub FETCH {
    my ($self, $index) = @_;
    return $self->[$index];
}

sub STORE { }

sub FETCHSIZE { scalar @{$_[0]} }

sub STORESIZE {  }


package Tie::Fighter::Hash;

sub TIEHASH {
    my $class = shift;
    my %foo = ( test => 42 );
    return bless \%foo, $class;
}

sub FETCH {
    my ($self, $key) = @_;
    return $self->{$key};
}

sub STORE { }

sub EXISTS {
    my ($self, $key) = @_;
    return exists $self->{$key};
}

sub DELETE { }

sub CLEAR { }

sub FIRSTKEY {
    my $self = shift;
    my $a = keys %$self; # reset each() iterator
    return each %$self;
}

sub NEXTKEY {
    my $self = shift;
    return each %$self;
}

sub SCALAR { }

package Tie::Fighter::Handle;

sub TIEHANDLE {
    my $i; return bless \$i, shift;
}

sub PRINT { }

sub READ { return 'foo' }

sub READLINE { return 'foo' }

package main;

use Test::More;
use Data::Printer;

my $var = 42;
is p($var), '42', 'untied scalar shows only the scalar';


tie $var, 'Tie::Fighter::Scalar';

is p($var), '1 (tied to Tie::Fighter::Scalar)', 'tied scalar contains tied message';

untie $var;

is p($var), '1', 'cleared (untied) scalar again shows no tie information';

my @var = (1);

is p(@var), '[
    [0] 1
]', 'untied array shows only the array';


tie @var, 'Tie::Fighter::Array';

is p(@var), '[
    [0] 2,
    [1] 3
] (tied to Tie::Fighter::Array)', 'tied array contains tied message';

untie @var;

is p(@var), '[
    [0] 1
]', 'cleared (untied) array again shows no tie information';

my %var = ( foo => 'bar' );

is p(%var), '{
    foo   "bar"
}', 'untied hash shows only the hash';

tie %var, 'Tie::Fighter::Hash';

is p(%var), '{
    test   42
} (tied to Tie::Fighter::Hash)', 'tied hash contains tied message';

untie %var;

is p(%var), '{
    foo   "bar"
}', 'cleared (untied) hash again shows no tie information';

$var = *DATA;
like p($var), qr/\*main::DATA/, 'untied handle properly referenced';
unlike p($var), qr/tied to/, 'untied handle shows only the handle itself';

tie *$var, 'Tie::Fighter::Handle';
like p($var), qr/tied to Tie::Fighter::Handle/, 'tied handle contains tied message';

untie *$var;
unlike p($var), qr/tied to/, 'cleared (untied) handle again shows no tie information';

done_testing;

__DATA__
test file!
