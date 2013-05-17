use strict;
use warnings;
use lib 't';

use Test::More tests => 11;
use VimFolds;

my $no_anon_folds = VimFolds->new(
    language      => 'perl',
    script_before => 'let perl_fold=1 | let perl_nofold_packages=1'
);

my $anon_folds = VimFolds->new(
    language      => 'perl',
    script_before => 'let perl_fold=1 | let perl_nofold_packages=1 | let perl_fold_anonymous_subs=1'
);

$no_anon_folds->folds_match(<<'END_PERL');
use strict;
use warnings;

my $anon_sub = sub {
    print "one\n";
    print "two\n";
    print "three\n";
};
END_PERL

$anon_folds->folds_match(<<'END_PERL');
use strict;
use warnings;

my $anon_sub = sub { # {{{
    print "one\n";
    print "two\n";
    print "three\n";
}; # }}}
END_PERL

$anon_folds->folds_match(<<'END_PERL');
use strict;
use warnings;

my %HASH = (
    super => 1,
    'sub' => 2,
);

sub something { # {{{
    my ( $self, $child ) = @_;

    # hello
    unless(ref $child) {
        $child = $child->new;
    }

    $self->current_node->append_child($child);
} # }}}
END_PERL

$anon_folds->folds_match(<<'END_PERL');
has parser_rules => (
    is      => 'ro',
    default => sub { [] },
);

sub _append_child { # {{{
    my ( $self, $child, %params ) = @_;

    unless(ref $child) {
        $child = $child->new(
            %params,
            parent => $self->current_node,
        );
    }

    $self->current_node->append_child($child);
    return $child;
} }}}
END_PERL

$anon_folds->folds_match(<<'END_PERL');
my $sub = sub :Attribute { # {{{
    say 'foo';
    say 'bar';
    say 'baz';
}; # }}}
END_PERL

$anon_folds->folds_match(<<'END_PERL');
my $sub = sub () { # {{{
    say 'foo';
    say 'bar';
    say 'baz';
}; # }}}
END_PERL

$anon_folds->folds_match(<<'END_PERL');
my $sub = sub () { # {{{
    my $string = q/foo } bar/;
    say 'more stuff';
}; # }}}
END_PERL

$anon_folds->folds_match(<<'END_PERL');
my $sub = sub () { # {{{
    my $perl = <<'END_PERL2';
sub {
    say 'hello'
}
END_PERL2
}; # }}}
END_PERL

$anon_folds->folds_match(<<'END_PERL');
my $sub = sub ()
{ # {{{
    say 'foo';
    say 'bar';
    say 'baz';
}; # }}}
END_PERL

$anon_folds->folds_match(<<'END_PERL', 'test folds with print { $fh } ... (anonymous ON)');
use strict;
use warnings;

sub foo { # {{{
    my ( $self, @params ) = @_;

    open my $fh, '> ', 'log.txt' or die $!;
    print { $fh } "warning!\n";
    close $fh;
} # }}}
END_PERL

$no_anon_folds->folds_match(<<'END_PERL', 'test folds with print { $fh } ... (anonymous OFF)');
use strict;
use warnings;

sub foo { # {{{
    my ( $self, @params ) = @_;

    open my $fh, '> ', 'log.txt' or die $!;
    print { $fh } "warning!\n";
    close $fh;
} # }}}
END_PERL
