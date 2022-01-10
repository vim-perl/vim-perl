use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
};

use Data::Printer {
    filters => {
       -external => [ 'Digest' ],
       HASH => sub { 'this is a hash' }
    },
};

my $data = 'I can has Digest?';

foreach my $module (qw( Digest::Adler32 Digest::MD2 Digest::MD4 Digest::MD5
                        Digest::SHA Digest::SHA1 
                        Digest::Whirlpool Digest::Haval256
)) {

    SKIP: {
        eval "use $module";
        skip "$module not available", 1 if $@;

        my $digest = $module->new;
        $digest->add( $data );

        my $dump = p $digest;
        my $named_dump = p $digest, digest => { show_class_name => 1 };

        my @list = ($digest, { foo => 1 });
        my $list_dump  = p @list;
        my $hex = $digest->hexdigest;

        is( $dump, $hex, $module );
        is( $named_dump, "$hex ($module)", "$module with class name" );

        is( $list_dump, "[
    [0] $hex,
    [1] this is a hash
]", "inline and class filters together ($module)"
        );

        is( p($digest), $digest->hexdigest . ' [reset]', "reset $module");
    };

}

done_testing;
