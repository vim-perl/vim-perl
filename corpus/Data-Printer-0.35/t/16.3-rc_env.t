use strict;
use warnings;
use Test::More;

sub create_rc_file {
    my ($filename, $content) = @_;

    my $file = File::Spec->catfile(
            File::HomeDir->my_home,
            $filename
    );

    if (-e $file) {
        plan skip_all => "File $filename should not be in test homedir";
    }
    umask 0022;
    open my $fh, '>', $file
        or plan skip_all => "error opening $filename: $!";

    print {$fh} $content
        or plan skip_all => "error writing to $filename: $!";

    close $fh;
    return $file;
}

my $standard_rcfile;
my $custom_rcfile;
BEGIN {
    delete $ENV{ANSI_COLORS_DISABLED};
    use_ok ('Term::ANSIColor');
    use_ok ('File::HomeDir::Test');
    use_ok ('File::HomeDir');
    use_ok ('File::Spec');

    $standard_rcfile = create_rc_file('.dataprinter',
        '{ colored => 1, color => { hash => "red" }, hash_separator => "  +  "}'
    );
    $custom_rcfile = create_rc_file('.customrc',
        '{ colored => 1, color => { hash => "green" }, hash_separator => "  %  "}'
    );
    $ENV{DATAPRINTERRC} = $custom_rcfile;

    # standard and custom rc files created
    # check that the custom rc overrides the standard one
    use_ok ('Data::Printer');

    unlink $standard_rcfile or fail('error removing test file');
    unlink $custom_rcfile   or fail('error removing test file');
};

my %hash = ( key => 'value' );

is( p(%hash), color('reset') . "{$/    "
              . colored('key', 'green')
              . '  %  '
              . q["] . colored('value', 'bright_yellow') . q["]
              . "$/}"
, 'custom rc file overrides standard rc file');

is( p(%hash, color => { hash => 'blue' }, hash_separator => '  *  ' ), color('reset') . "{$/    "
              . colored('key', 'blue')
              . '  *  '
              . q["] . colored('value', 'bright_yellow') . q["]
              . "$/}"
, 'in-code configuration overrides custom rc file');

done_testing;
