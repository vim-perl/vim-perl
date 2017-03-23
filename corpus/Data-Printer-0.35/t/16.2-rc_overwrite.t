use strict;
use warnings;
use Test::More;

my $file;
BEGIN {
    delete $ENV{ANSI_COLORS_DISABLED};
    delete $ENV{DATAPRINTERRC};
    use Term::ANSIColor;
    use File::HomeDir::Test;
    use File::HomeDir;
    use File::Spec;

    $file = File::Spec->catfile(
            File::HomeDir->my_home,
            'my_rc_file'
    );

    if (-e $file) {
        plan skip_all => 'File my_rc_file should not be in test homedir';
    }
    umask 0022;
    open my $fh, '>', $file
        or plan skip_all => "error opening .dataprinter: $!";

    print {$fh} '{ colored => 0, multiline => 0, hash_separator => "+"}'
        or plan skip_all => "error writing to .dataprinter: $!";

    close $fh;

    # file created and in place, let's load up our
    # module and see if it overrides the default conf
    # with our .dataprinter RC file
    use_ok ('Data::Printer', rc_file => $file );
    unlink $file or fail('error removing test file');
};

my %hash = ( key => 'value' );

is(
    p(%hash),
    '{ key+"value" }',
    'overwritten rc file'
);

done_testing;
