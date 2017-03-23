use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose;

    has bar => (
        is       => 'ro',
        weak_ref => 1,
    );
}

{
    package MyScopeGuard;

    sub new {
        my ($class, $cb) = @_;
        bless { cb => $cb }, $class;
    }

    sub DESTROY { shift->{cb}->() }
}

{
    my $destroyed = 0;

    my $foo = do {
        my $bar = MyScopeGuard->new(sub { $destroyed++ });
        my $foo = Foo->new({ bar => $bar });
        my $clone = $foo->meta->clone_object($foo);

        is $destroyed, 0;

        $clone;
    };

    isa_ok($foo, 'Foo');
    is $foo->bar, undef;
    is $destroyed, 1;
}

{
    my $clone;
    {
        my $anon = Moose::Meta::Class->create_anon_class;

        my $foo = $anon->new_object;
        isa_ok($foo, $anon->name);
        ok(Class::MOP::class_of($foo), "has a metaclass");

        $clone = $anon->clone_object($foo);
        isa_ok($clone, $anon->name);
        ok(Class::MOP::class_of($clone), "has a metaclass");
    }

    ok(Class::MOP::class_of($clone), "still has a metaclass");
}

{
    package Foo::Meta::Attr::Trait;
    use Moose::Role;

    has value_slot => (
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => sub { shift->name },
    );

    has count_slot => (
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => sub { '<<COUNT>>' . shift->name },
    );

    sub slots {
        my $self = shift;
        return ($self->value_slot, $self->count_slot);
    }

    sub _set_count {
        my $self = shift;
        my ($instance) = @_;
        my $mi = $self->associated_class->get_meta_instance;
        $mi->set_slot_value(
            $instance,
            $self->count_slot,
            ($mi->get_slot_value($instance, $self->count_slot) || 0) + 1,
        );
    }

    sub _clear_count {
        my $self = shift;
        my ($instance) = @_;
        $self->associated_class->get_meta_instance->deinitialize_slot(
            $instance, $self->count_slot
        );
    }

    sub has_count {
        my $self = shift;
        my ($instance) = @_;
        $self->associated_class->get_meta_instance->has_slot_value(
            $instance, $self->count_slot
        );
    }

    sub count {
        my $self = shift;
        my ($instance) = @_;
        $self->associated_class->get_meta_instance->get_slot_value(
            $instance, $self->count_slot
        );
    }

    after set_initial_value => sub {
        shift->_set_count(@_);
    };

    after set_value => sub {
        shift->_set_count(@_);
    };

    around _inline_instance_set => sub {
        my $orig = shift;
        my $self = shift;
        my ($instance) = @_;

        my $mi = $self->associated_class->get_meta_instance;

        return 'do { '
                 . $mi->inline_set_slot_value(
                       $instance,
                       $self->count_slot,
                       $mi->inline_get_slot_value(
                           $instance, $self->count_slot
                       ) . ' + 1'
                   ) . ';'
                 . $self->$orig(@_)
             . '}';
    };

    after clear_value => sub {
        shift->_clear_count(@_);
    };
}

{
    package Bar;
    use Moose;
    Moose::Util::MetaRole::apply_metaroles(
        for => __PACKAGE__,
        class_metaroles => {
            attribute => ['Foo::Meta::Attr::Trait'],
        },
    );

    has baz => ( is => 'rw' );
}

{
    my $attr = Bar->meta->find_attribute_by_name('baz');

    my $bar = Bar->new(baz => 1);
    is($attr->count($bar), 1, "right count");

    $bar->baz(2);
    is($attr->count($bar), 2, "right count");

    my $clone = $bar->meta->clone_object($bar);
    is($attr->count($clone), $attr->count($bar), "right count");
}

done_testing;
