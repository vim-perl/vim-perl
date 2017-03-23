use strict;
use warnings;

use Test::More;

use Class::MOP;

=pod

This tests a bug which is fixed in 0.22 by localizing all the $@'s around any
evals.

This a real pain to track down.

Moral of the story:

  ALWAYS localize your globals :)

=cut

{
    package Company;
    use strict;
    use warnings;
    use metaclass;

    sub new {
        my ($class) = @_;
        return bless {} => $class;
    }

    sub employees {
        die "This didnt work";
    }

    sub DESTROY {
        my $self = shift;
        foreach
            my $method ( $self->meta->find_all_methods_by_name('DEMOLISH') ) {
            $method->{code}->($self);
        }
    }
}

eval {
    my $c = Company->new();
    $c->employees();
};
ok( $@, '... we die correctly with bad args' );

done_testing;
