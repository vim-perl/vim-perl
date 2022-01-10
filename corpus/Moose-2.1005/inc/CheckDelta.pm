package inc::CheckDelta;
use Moose;

use Path::Class;

with 'Dist::Zilla::Role::AfterBuild';

sub after_build {
    my $self = shift;

    return unless $ENV{DZIL_RELEASING};

    my ($delta) = grep { $_->name eq 'lib/Moose/Manual/Delta.pod' }
                       @{ $self->zilla->files };

    die "Moose::Manual::Delta still contains \$NEXT"
        if $delta->content =~ /\$NEXT/;
}

1;
