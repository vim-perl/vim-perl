package NoInlineAttribute;

use Moose::Meta::Class;
use Moose::Role;

around accessor_metaclass => sub {
    my $orig = shift;
    my $self = shift;

    my $class = $self->$orig();

    return Moose::Meta::Class->create_anon_class(
        superclasses => [$class],
        roles        => ['NoInlineAccessor'],
        cache        => 1,
    )->name;
};

no Moose::Role;

{
    package NoInlineAccessor;

    use Moose::Role;

    sub is_inline { 0 }
}

1;
