package Bar7::Meta::Trait2;
use Moose::Role;

has foo => (
    traits  => ['Array'],
    handles => {
        push_foo => 'push',
    },
);

no Moose::Role;

1;
