use strict;
use warnings;

my ($var, $filename);
BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
    use File::HomeDir;
    use File::Spec;
    use Test::More;
    use Fcntl;

    use Data::Printer;

    $filename = File::Spec->catfile(
        File::HomeDir->my_home, 'test_file.dat'
    );
};

if ( open $var, '>', $filename ) {
    my $str = p $var;

    my @layers = ();
    eval { @layers = PerlIO::get_layers $var };

    close $var;

    unless ($@) {
        foreach my $l (@layers) {
            like $str, qr/$l/, "layer $l present in info";
        }
    }
}
else {
    diag("error writing to $filename: $!");
}


SKIP: {
    skip "error opening $filename for (write) testing: $!", 4
        unless open $var, '>', $filename;

    my $flags;
    eval { $flags = fcntl($var, F_GETFL, 0) };
    skip 'fcntl not fully supported', 4 if $@ or !$flags;

    like p($var), qr{write-only}, 'write-only handle';
    close $var;

    skip "error appending to $filename: $!", 3
        unless open $var, '+>>', $filename;

    like p($var), qr{read/write}, 'read/write handle';
    like p($var), qr/flags:[^,]+append/, 'append flag';

    close $var;

    skip "error reading from $filename: $!", 1
        unless open $var, '<', $filename;

    like p($var), qr{read-only}, 'read-only handle';
    close $var;
};

done_testing();

