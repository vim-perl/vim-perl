use strict;
use warnings;
use Test::More;

my $file;
BEGIN {
    delete $ENV{ANSI_COLORS_DISABLED};
    use_ok ('Term::ANSIColor');
    use_ok ('File::HomeDir::Test');
    use_ok ('File::HomeDir');
    use_ok ('File::Spec');

    $file = File::Spec->catfile(
            File::HomeDir->my_home,
            '.customrc'
    );

    if (-e $file) {
        plan skip_all => 'File .customrc should not be in test homedir';
    }
    umask 0022;
    open my $fh, '>', $file
        or plan skip_all => "error opening .customrc: $!";

    print {$fh} '{ colored => 1, color => { hash => "red" }, hash_separator => "  +  "}'
        or plan skip_all => "error writing to .customrc: $!";

    close $fh;

    $ENV{DATAPRINTERRC} = $file;

    # file created and in place, check that the explicit configuration below
    # overrides the custom rc file
    use_ok ('Data::Printer', {
                color => {
                    hash => 'blue'
                },
                hash_separator => '  *  ',
           });
    unlink $file or fail('error removing test file');
};

my %hash = ( key => 'value' );

is( p(%hash), color('reset') . "{$/    "
              . colored('key', 'blue')
              . '  *  '
              . q["] . colored('value', 'bright_yellow') . q["]
              . "$/}"
, 'global configuration overrides our custom rc file');

done_testing;
