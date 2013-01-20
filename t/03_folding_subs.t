use strict;
use warnings;
use lib 't';

use Test::More tests => 1;
use VimFolds;

my $folds = VimFolds->new(
    language      => 'perl',
    script_before => 'let perl_fold=1 | let perl_nofold_packages=1'
);

$folds->folds_match(<<'END_PERL');
use strict;
use warnings;

sub foo { # {{{
    my ( $self, @params ) = @_;

    print "hello!\n";
} # }}}
END_PERL
