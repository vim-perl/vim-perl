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

my $code_rcfile;
my $env_rcfile;
BEGIN {
    delete $ENV{ANSI_COLORS_DISABLED};
    use_ok ('Term::ANSIColor');
    use_ok ('File::HomeDir::Test');
    use_ok ('File::HomeDir');
    use_ok ('File::Spec');

    $code_rcfile = create_rc_file('.coderc',
        '{ colored => 1, color => { hash => "red" }, hash_separator => "  +  "}'
    );
    $env_rcfile = create_rc_file('.envrc',
        '{ colored => 1, color => { hash => "green" }, hash_separator => "  %  "}'
    );
    $ENV{DATAPRINTERRC} = $env_rcfile;

    # code and env rc files created
    # check that the rc file specified with rc_file overrides the one
    # specified with $ENV{DATAPRINTERRC}
    use_ok ('Data::Printer', rc_file => $code_rcfile);

    unlink $code_rcfile or fail('error removing test file');
    unlink $env_rcfile  or fail('error removing test file');
};

my %hash = ( key => 'value' );

is( p(%hash), color('reset') . "{$/    "
              . colored('key', 'red')
              . '  +  '
              . q["] . colored('value', 'bright_yellow') . q["]
              . "$/}"
, 'custom configuration overrides standard rc file');

done_testing;
