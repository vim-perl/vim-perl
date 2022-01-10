package inc::RequireAuthorDeps;

use Class::Load qw(load_class);
use Moose;

use CPAN::Meta::Requirements;
use Try::Tiny;

with 'Dist::Zilla::Role::BeforeRelease';

sub before_release {
    my $self = shift;

    $self->log("Ensuring all author dependencies are installed");
    my $req = CPAN::Meta::Requirements->new;
    my $prereqs = $self->zilla->prereqs;

    for my $phase (qw(build test configure runtime develop)) {
        $req->add_requirements($prereqs->requirements_for($phase, 'requires'));
    }

    for my $mod (grep { $_ ne 'perl' } $req->required_modules) {
        load_class($mod);
    }
}

1;
