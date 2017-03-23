package inc::MakeMaker;

use Moose;

use lib 'inc';

use MMHelper;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my $self = shift;

    my $tmpl = super();

    my $ccflags = MMHelper::ccflags_dyn();
    $tmpl =~ s/^(WriteMakefile\()/\$WriteMakefileArgs{CCFLAGS} = $ccflags;\n\n$1/m;

    return $tmpl . "\n\n" . MMHelper::my_package_subs();
};

override _build_WriteMakefile_args => sub {
    my $self = shift;

    my $args = super();

    return {
        %{$args},
        MMHelper::mm_args(),
    };
};

override test => sub {
    my $self = shift;

    local $ENV{PERL5LIB} = join ':',
        grep {defined} @ENV{ 'PERL5LIB', 'DZIL_TEST_INC' };

    super();
};

1;
