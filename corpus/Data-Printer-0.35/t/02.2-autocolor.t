use strict;
use warnings;
use Test::More;

BEGIN {
    delete $ENV{ANSI_COLORS_DISABLED};
    delete $ENV{DATAPRINTERRC};
    use File::HomeDir::Test;  # avoid user's .dataprinter
    use Term::ANSIColor;
};

eval 'use IO::Pty::Easy';
plan skip_all => 'IO::Pty::Easy required for auto-colored tests' if $@;


my $client_script = <<'EOSCRIPT';
    BEGIN {
        delete $ENV{ANSI_COLORS_DISABLED};
        use File::HomeDir::Test;  # avoid user's .dataprinter
        use Data::Printer;
    };

    my $num = 3.14;
    p $num;

EOSCRIPT

my $pty = IO::Pty::Easy->new;

$pty->spawn( "$^X", "-e", $client_script );

my $output = $pty->read;

my $colored = color('reset') . colored('3.14', 'bright_blue') . $/;

is
    $output,
    $colored,
    'p() auto colors the output properly'
;

done_testing;
