package # pretend this doesn't exist, because it shouldn't
    Moose::Error::Util;

use strict;
use warnings;

# this intentionally exists to have a place to put this logic that doesn't
# involve loading Class::MOP, so... don't do that

use Carp::Heavy;

sub _create_error_carpmess {
    my %args = @_;

    my $carp_level = 3 + ( $args{depth} || 0 );
    local $Carp::MaxArgNums = 20; # default is 8, usually we use named args which gets messier though

    my @args = exists $args{message} ? $args{message} : ();

    if ( $args{longmess} || $Carp::Verbose ) {
        local $Carp::CarpLevel = ( $Carp::CarpLevel || 0 ) + $carp_level;
        return Carp::longmess(@args);
    } else {
        return Carp::ret_summary($carp_level, @args);
    }
}

sub create_error_croak {
    _create_error_carpmess(@_);
}

sub create_error_confess {
    _create_error_carpmess(@_, longmess => 1);
}

sub create_error {
    if (defined $ENV{MOOSE_ERROR_STYLE} && $ENV{MOOSE_ERROR_STYLE} eq 'croak') {
        create_error_croak(@_);
    }
    else {
        create_error_confess(@_);
    }
}

1;

__END__

=pod

=for pod_coverage_needs_some_pod

=cut

