package inc::ExtractInlineTests;

use Moose;

with 'Dist::Zilla::Role::FileGatherer';

use File::Basename qw( basename );
use File::Find::Rule;
use File::Spec;
use File::Temp qw( tempdir );
use inc::MyInline;
use Test::Inline;

sub gather_files {
    my $self = shift;
    my $arg  = shift;

    my $inline = Test::Inline->new(
        verbose        => 0,
        ExtractHandler => 'My::Extract',
        ContentHandler => 'My::Content',
        OutputHandler  => My::Output->new($self),
    );

    for my $pod (
        File::Find::Rule->file->name(qr/\.pod$/)->in('lib/Moose/Cookbook') ) {
        $inline->add($pod);
    }

    $inline->save;
}

{
    package My::Output;

    sub new {
        my $class = shift;
        my $dzil  = shift;

        return bless { dzil => $dzil }, $class;
    }

    sub write {
        my $self    = shift;
        my $name    = shift;
        my $content = shift;

        $name =~ s/^moose_cookbook_//;

        $self->{dzil}->add_file(
            Dist::Zilla::File::InMemory->new(
                name    => "t/recipes/$name",
                content => $content,
            )
        );

        return 1;
    }
}

1;
