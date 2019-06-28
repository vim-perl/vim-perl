use strict;
use warnings;
use lib 'tools';

use Test::More tests => 7;
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

$folds = Local::VimFolds->new(
    language => 'perl',
    options  => {
        perl_fold                  => 1,
        perl_nofold_packages       => 1,
        perl_no_subprototype_error => 1,
    },
);

$folds->folds_match(<<'END_PERL', 'test folds for subs with signatures');
sub add($x, $y) { # {{{
    return $x + $y;
} # }}}

sub subtract($x, $y) { # {{{
    return $x - $y;
} # }}}
END_PERL

$folds = Local::VimFolds->new(
    language => 'perl',
    options  => {
        perl_fold                => 1,
        perl_fold_anonymous_subs => 1,
    },
);

$folds->folds_match(<<'END_PERL', 'test folds when method calls contain a post-deref slice');
sub add_domain_filter ( $self, $domain_filter ) { # {{{
    my $index = {};

    $index->@{ $DOMAIN_FILTER->@*, $domain_filter->@* } = ();

    return;
} # }}}
END_PERL

# block fold tests - I know these don't really belong here, but we can
# break them out into a new file if they get extended
$folds = Local::VimFolds->new(
    language => 'perl',
    options  => {
        perl_fold        => 1,
        perl_fold_blocks => 1,
    },
);

TODO: {
    local $TODO = q{foreach folding overlaps between blocks};

    $folds->folds_match(<<'END_PERL', 'test block folds');
for my $i (@list) { # {{{
    $total += $i;
} # }}}

foreach my $i (@list) { # {{{
    $total += $i;
} # }}}
END_PERL
}

$folds = Local::VimFolds->new(
    language => 'perl',
    options  => {
        perl_fold                  => 1,
        perl_nofold_packages       => 1,
        perl_fold_anonymous_subs   => 1,
        perl_no_subprototype_error => 1,
        perl_sub_signatures        => 1,
    },
);

$folds->folds_match(<<'END_PERL', 'test folds with signatures and multiple attributes');
sub asas::asdsad::adsa : prototype() : lvalue : method ($d) { # {{{
    return;
} # }}}

sub asdsad : prototype() : lvalue : method($d) { # {{{
    my $s = sub : prototype($$) ( $a, $v ) { # {{{
        return;
    }; # }}}

    return;
} # }}}
END_PERL
