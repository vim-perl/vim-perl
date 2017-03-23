use strict;
use warnings;
use Test::More;

my $has_timepiece;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter

    # Time::Piece is only able to overload
    # localtime() if it's loaded during compile-time
    eval 'use Time::Piece';
    $has_timepiece = $@ ? 0 : 1;
};

use Data::Printer {
    filters => {
       -external => [ 'DateTime' ],
       HASH => sub { 'this is a hash' }
    },
};

SKIP: {
    my $how_many = 3;
    skip 'Time::Piece not available', $how_many
        unless $has_timepiece;

    my $t = localtime 1234567890;
    skip 'localtime not returning an object', $how_many
        unless ref $t and ref $t eq 'Time::Piece';

    my @list = ($t, { foo => 1 } );

    # we can't use a literal in our tests because of
    # timezone and epoch issues
    my $time_str = $t->cdate;

    is ( p($t), $time_str, 'Time::Piece' );
    is ( p($t, datetime => { show_class_name => 1 }),
         "$time_str (Time::Piece)",
         'Time::Piece with class name'
    );
    is ( p(@list), "[
    [0] $time_str,
    [1] this is a hash
]", 'inline and class filters together (Time::Piece)'
    );
};

SKIP: {
    eval 'use DateTime';
    skip 'DateTime not available', 4 if $@;

    my $d1 = DateTime->new( year => 1981, month =>  9, day => 29 );
    my $d2 = DateTime->new( year => 1984, month => 11, day => 15 );
    my $diff = $d2 - $d1;

    is( p($d1), '1981-09-29T00:00:00 [floating]', 'DateTime' );
    is( p($d1, datetime => { show_timezone => 0 }), '1981-09-29T00:00:00', 'DateTime without TZ data' );
    is( p($diff), '3y 1m 16d 0h 0m 0s', 'DateTime::Duration' );
    my @list = ($d1, { foo => 1 });
    is( p(@list), '[
    [0] 1981-09-29T00:00:00 [floating],
    [1] this is a hash
]', 'inline and class filters together (DateTime)'
    );
};

SKIP: {
    eval 'use DateTime::TimeZone';
    skip 'DateTime::TimeZone not available', 2 if $@;

    my $d = DateTime::TimeZone->new( name => 'America/Sao_Paulo' );
    is( p($d), 'America/Sao_Paulo', 'DateTime::TimeZone' );
    my @list = ($d, { foo => 1 });
    is( p(@list), '[
    [0] America/Sao_Paulo,
    [1] this is a hash
]', 'inline and class filters together (DateTime::TimeZone)'
    );
};

SKIP: {
    eval 'use DateTime::Incomplete';
    skip 'DateTime::Incomplete not available', 2 if $@;

    my $d = DateTime::Incomplete->new( year => 2003 );
    is( p($d), '2003-xx-xxTxx:xx:xx', 'DateTime::Incomplete' );
    my @list = ($d, { foo => 1 });
    is( p(@list), '[
    [0] 2003-xx-xxTxx:xx:xx,
    [1] this is a hash
]', 'inline and class filters together (DateTime::Incomplete)'
    );
};

SKIP: {
    eval 'use DateTime::Tiny';
    skip 'DateTime::Tiny not available', 2 if $@;

    my $d = DateTime::Tiny->new( year => 2003, month => 3, day => 11 );
    is( p($d), '2003-03-11T00:00:00', 'DateTime::Tiny' );
    my @list = ($d, { foo => 1 });
    is( p(@list), '[
    [0] 2003-03-11T00:00:00,
    [1] this is a hash
]', 'inline and class filters together (DateTime::Tiny)'
    );
};

SKIP: {
    eval 'use Date::Calc::Object';
    skip 'Date::Calc::Object not available', 2 if $@;

    my $d = Date::Calc::Object->localtime( 1234567890 );
    my $string = $d->string(2);
    is( p($d), $string, 'Date::Calc::Object' );
    my @list = ($d, { foo => 1 });
    is( p(@list), "[
    [0] $string,
    [1] this is a hash
]", 'inline and class filters together (Date::Calc::Object)'
    );
};

SKIP: {
    eval 'use Date::Pcalc::Object';
    skip 'Date::Pcalc::Object not available', 2 if $@;

    my $d = Date::Pcalc::Object->localtime( 1234567890 );
    my $string = $d->string(2);
    is( p($d), $string, 'Date::Pcalc::Object' );
    my @list = ($d, { foo => 1 });
    is( p(@list), "[
    [0] $string,
    [1] this is a hash
]", 'inline and class filters together (Date::Pcalc::Object)'
    );
};

SKIP: {
    my $how_many = 4;
    eval 'use Date::Handler';
    skip 'Date::Handler not available', $how_many if $@;
    eval 'use Date::Handler::Delta';
    skip 'Date::Handler::Delta not available', $how_many if $@;


    my $d = Date::Handler->new( date => 1234567890 );
    my $string = "$d";
    is( p($d), $string, 'Date::Handler' );
    my @list = ($d, { foo => 1 });
    is( p(@list), "[
    [0] $string,
    [1] this is a hash
]", 'inline and class filters together (Date::Handler)'
    );

    my $delta = Date::Handler->new( date => 1234567893 ) - $d;
    $string = $delta->AsScalar;
    is( p($delta), $string, 'Date::Handler::Delta' );
    @list = ($delta, { foo => 1 });
    is( p(@list), "[
    [0] $string,
    [1] this is a hash
]", 'inline and class filters together (Date::Handler::Delta)'
    );
};

done_testing;
