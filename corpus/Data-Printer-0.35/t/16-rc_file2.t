use strict;
use warnings;
use Test::More;

my $file;
BEGIN {
    delete $ENV{ANSI_COLORS_DISABLED};
    delete $ENV{DATAPRINTERRC};
    use_ok ('Term::ANSIColor');
    use_ok ('File::HomeDir::Test');
    use_ok ('File::HomeDir');
    use_ok ('File::Spec');

    $file = File::Spec->catfile(
            File::HomeDir->my_home,
            '.dataprinter'
    );

    if (-e $file) {
        plan skip_all => 'File .dataprinter should not be in test homedir';
    }
    umask 0022;
    open my $fh, '>', $file
        or plan skip_all => "error opening .dataprinter: $!";

    print {$fh} '{ colored => 1, color => { hash => "red" }, hash_separator => "  +  "}'
        or plan skip_all => "error writing to .dataprinter: $!";

    close $fh;

    # file created and in place, let's load up our
    # module and see if it overrides the default conf
    # with our .dataprinter RC file
    use_ok ('Data::Printer', {
                color => {
                    hash => 'blue'
                },
                hash_separator => '  *  ',
           });
    unlink $file or fail('error removing test file');
};

my %hash = ( key => 'value' );

is( p(%hash, color => { hash => 'blue' }, hash_separator => '  *  ' ), color('reset') . "{$/    "
              . colored('key', 'blue')
              . '  *  '
              . q["] . colored('value', 'bright_yellow') . q["]
              . "$/}"
, 'global configuration overrides our rc file');

done_testing;
