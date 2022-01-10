package inc::Clean;
use Moose;

with 'Dist::Zilla::Role::BeforeBuild';

sub before_build {
    my $self = shift;

    if (-e 'Makefile') {
        $self->log("Running make distclean to clear out build cruft");
        unless (fork) {
            close(STDIN);
            close(STDOUT);
            close(STDERR);
            { exec("$^X Makefile.PL && make distclean") }
            die "couldn't exec: $!";
        }
    }

    if (-e 'META.yml') {
        $self->log("Removing existing META.yml file");
        unlink('META.yml');
    }
}
