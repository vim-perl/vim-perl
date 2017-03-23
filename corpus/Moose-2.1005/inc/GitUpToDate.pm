package inc::GitUpToDate;
use Moose;

with 'Dist::Zilla::Role::BeforeBuild';

sub git {
    if (wantarray) {
        chomp(my @ret = qx{git $_[0]});
        return @ret;
    }
    else {
        chomp(my $ret = qx{git $_[0]});
        return $ret;
    }
}

sub before_build {
    my $self = shift;

    return unless $ENV{DZIL_RELEASING};

    my $branch = git "symbolic-ref HEAD";
    die "Could not get the current branch"
        unless $branch;

    $branch =~ s{refs/heads/}{};

    $self->log("Ensuring branch $branch is up to date");

    git "fetch origin";
    my $origin = git "rev-parse origin/$branch";
    my $head = git "rev-parse HEAD";

    die "Branch $branch is not up to date (origin: $origin, HEAD: $head)"
        if $origin ne $head;
}

1;
