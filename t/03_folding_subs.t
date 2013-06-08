use strict;
use warnings;
use lib 'tools';

use Test::More tests => 3;
use Local::VimFolds;

my $folds = Local::VimFolds->new(
    language => 'perl',
    options  => {
        perl_fold            => 1,
        perl_nofold_packages => 1,
    },
);

$folds->folds_match(<<'END_PERL', 'test folds on a regular sub');
use strict;
use warnings;

sub foo { # {{{
    my ( $self, @params ) = @_;

    print "hello!\n";
} # }}}
END_PERL

TODO: {
    local $TODO = q{Next-line subs don't fold properly yet'};

    $folds->folds_match(<<'END_PERL', 'test folds on a sub with the opening brace on the next line');
use strict;
use warnings;

sub foo
{ # {{{
    my ( $self, @params ) = @_;

    print "hello!\n";
} # }}}
END_PERL
}

$folds->folds_match(<<'END_PERL', 'test folds for a sub prototype');
use strict;
use warnings;

sub foo;

sub foo { # {{{
    my ( $self, @params ) = @_;

    print "hello!\n";
} # }}}
END_PERL
