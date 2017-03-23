
package Moose::Meta::Class;
BEGIN {
  $Moose::Meta::Class::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Class::VERSION = '2.1005';
}

use strict;
use warnings;

use Class::Load qw(load_class);
use Class::MOP;
use Carp qw( confess );
use Data::OptList;
use List::Util qw( first );
use List::MoreUtils qw( any all uniq first_index );
use Scalar::Util 'blessed';

use Moose::Meta::Method::Overridden;
use Moose::Meta::Method::Augmented;
use Moose::Error::Default;
use Moose::Meta::Class::Immutable::Trait;
use Moose::Meta::Method::Constructor;
use Moose::Meta::Method::Destructor;
use Moose::Meta::Method::Meta;
use Moose::Util;
use Class::MOP::MiniTrait;

use base 'Class::MOP::Class';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

__PACKAGE__->meta->add_attribute('roles' => (
    reader  => 'roles',
    default => sub { [] },
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute('role_applications' => (
    reader  => '_get_role_applications',
    default => sub { [] },
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute(
    Class::MOP::Attribute->new('immutable_trait' => (
        accessor => "immutable_trait",
        default  => 'Moose::Meta::Class::Immutable::Trait',
        Class::MOP::_definition_context(),
    ))
);

__PACKAGE__->meta->add_attribute('constructor_class' => (
    accessor => 'constructor_class',
    default  => 'Moose::Meta::Method::Constructor',
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute('destructor_class' => (
    accessor => 'destructor_class',
    default  => 'Moose::Meta::Method::Destructor',
    Class::MOP::_definition_context(),
));

__PACKAGE__->meta->add_attribute('error_class' => (
    accessor => 'error_class',
    default  => 'Moose::Error::Default',
    Class::MOP::_definition_context(),
));

sub initialize {
    my $class = shift;
    my @args = @_;
    unshift @args, 'package' if @args % 2;
    my %opts = @args;
    my $package = delete $opts{package};
    return Class::MOP::get_metaclass_by_name($package)
        || $class->SUPER::initialize($package,
                'attribute_metaclass' => 'Moose::Meta::Attribute',
                'method_metaclass'    => 'Moose::Meta::Method',
                'instance_metaclass'  => 'Moose::Meta::Instance',
                %opts,
            );
}

sub create {
    my $class = shift;
    my @args = @_;

    unshift @args, 'package' if @args % 2 == 1;
    my %options = @args;

    (ref $options{roles} eq 'ARRAY')
        || $class->throw_error("You must pass an ARRAY ref of roles", data => $options{roles})
            if exists $options{roles};

    my $package = delete $options{package};
    my $roles   = delete $options{roles};

    my $new_meta = $class->SUPER::create($package, %options);

    if ($roles) {
        Moose::Util::apply_all_roles( $new_meta, @$roles );
    }

    return $new_meta;
}

sub _meta_method_class { 'Moose::Meta::Method::Meta' }

sub _anon_package_prefix { 'Moose::Meta::Class::__ANON__::SERIAL::' }

sub _anon_cache_key {
    my $class = shift;
    my %options = @_;

    my $superclass_key = join('|',
        map { $_->[0] } @{ Data::OptList::mkopt($options{superclasses} || []) }
    );

    my $roles = Data::OptList::mkopt(($options{roles} || []), {
        moniker  => 'role',
        val_test => sub { ref($_[0]) eq 'HASH' },
    });

    my @role_keys;
    for my $role_spec (@$roles) {
        my ($role, $params) = @$role_spec;
        $params = { %$params } if $params;

        my $key = blessed($role) ? $role->name : $role;

        if ($params && %$params) {
            my $alias    = delete $params->{'-alias'}
                        || delete $params->{'alias'}
                        || {};
            my $excludes = delete $params->{'-excludes'}
                        || delete $params->{'excludes'}
                        || [];
            $excludes = [$excludes] unless ref($excludes) eq 'ARRAY';

            if (%$params) {
                warn "Roles with parameters cannot be cached. Consider "
                   . "applying the parameters before calling "
                   . "create_anon_class, or using 'weaken => 0' instead";
                return;
            }

            my $alias_key = join('%',
                map { $_ => $alias->{$_} } sort keys %$alias
            );
            my $excludes_key = join('%',
                sort @$excludes
            );
            $key .= '<' . join('+', 'a', $alias_key, 'e', $excludes_key) . '>';
        }

        push @role_keys, $key;
    }

    my $role_key = join('|', sort @role_keys);

    # Makes something like Super::Class|Super::Class::2=Role|Role::1
    return join('=', $superclass_key, $role_key);
}

sub reinitialize {
    my $self = shift;
    my $pkg  = shift;

    my $meta = blessed $pkg ? $pkg : Class::MOP::class_of($pkg);

    my %existing_classes;
    if ($meta) {
        %existing_classes = map { $_ => $meta->$_() } qw(
            attribute_metaclass
            method_metaclass
            wrapped_method_metaclass
            instance_metaclass
            constructor_class
            destructor_class
            error_class
        );
    }

    return $self->SUPER::reinitialize(
        $pkg,
        %existing_classes,
        @_,
    );
}

sub add_role {
    my ($self, $role) = @_;
    (blessed($role) && $role->isa('Moose::Meta::Role'))
        || $self->throw_error("Roles must be instances of Moose::Meta::Role", data => $role);
    push @{$self->roles} => $role;
}

sub role_applications {
    my ($self) = @_;

    return @{$self->_get_role_applications};
}

sub add_role_application {
    my ($self, $application) = @_;
    (blessed($application) && $application->isa('Moose::Meta::Role::Application::ToClass'))
        || $self->throw_error("Role applications must be instances of Moose::Meta::Role::Application::ToClass", data => $application);
    push @{$self->_get_role_applications} => $application;
}

sub calculate_all_roles {
    my $self = shift;
    my %seen;
    grep { !$seen{$_->name}++ } map { $_->calculate_all_roles } @{ $self->roles };
}

sub _roles_with_inheritance {
    my $self = shift;
    my %seen;
    grep { !$seen{$_->name}++ }
         map { Class::MOP::class_of($_)->can('roles')
                   ? @{ Class::MOP::class_of($_)->roles }
                   : () }
             $self->linearized_isa;
}

sub calculate_all_roles_with_inheritance {
    my $self = shift;
    my %seen;
    grep { !$seen{$_->name}++ }
         map { Class::MOP::class_of($_)->can('calculate_all_roles')
                   ? Class::MOP::class_of($_)->calculate_all_roles
                   : () }
             $self->linearized_isa;
}

sub does_role {
    my ($self, $role_name) = @_;

    (defined $role_name)
        || $self->throw_error("You must supply a role name to look for");

    foreach my $class ($self->class_precedence_list) {
        my $meta = Class::MOP::class_of($class);
        # when a Moose metaclass is itself extended with a role,
        # this check needs to be done since some items in the
        # class_precedence_list might in fact be Class::MOP
        # based still.
        next unless $meta && $meta->can('roles');
        foreach my $role (@{$meta->roles}) {
            return 1 if $role->does_role($role_name);
        }
    }
    return 0;
}

sub excludes_role {
    my ($self, $role_name) = @_;

    (defined $role_name)
        || $self->throw_error("You must supply a role name to look for");

    foreach my $class ($self->class_precedence_list) {
        my $meta = Class::MOP::class_of($class);
        # when a Moose metaclass is itself extended with a role,
        # this check needs to be done since some items in the
        # class_precedence_list might in fact be Class::MOP
        # based still.
        next unless $meta && $meta->can('roles');
        foreach my $role (@{$meta->roles}) {
            return 1 if $role->excludes_role($role_name);
        }
    }
    return 0;
}

sub new_object {
    my $self   = shift;
    my $params = @_ == 1 ? $_[0] : {@_};
    my $object = $self->SUPER::new_object($params);

    $self->_call_all_triggers($object, $params);

    $object->BUILDALL($params) if $object->can('BUILDALL');

    return $object;
}

sub _call_all_triggers {
    my ($self, $object, $params) = @_;

    foreach my $attr ( $self->get_all_attributes() ) {

        next unless $attr->can('has_trigger') && $attr->has_trigger;

        my $init_arg = $attr->init_arg;
        next unless defined $init_arg;
        next unless exists $params->{$init_arg};

        $attr->trigger->(
            $object,
            (
                  $attr->should_coerce
                ? $attr->get_read_method_ref->($object)
                : $params->{$init_arg}
            ),
        );
    }
}

sub _generate_fallback_constructor {
    my $self = shift;
    my ($class) = @_;
    return $class . '->Moose::Object::new(@_)'
}

sub _inline_params {
    my $self = shift;
    my ($params, $class) = @_;
    return (
        'my ' . $params . ' = ',
        $self->_inline_BUILDARGS($class, '@_'),
        ';',
    );
}

sub _inline_BUILDARGS {
    my $self = shift;
    my ($class, $args) = @_;

    my $buildargs = $self->find_method_by_name("BUILDARGS");

    if ($args eq '@_'
     && (!$buildargs or $buildargs->body == \&Moose::Object::BUILDARGS)) {
        return (
            'do {',
                'my $params;',
                'if (scalar @_ == 1) {',
                    'if (!defined($_[0]) || ref($_[0]) ne \'HASH\') {',
                        $self->_inline_throw_error(
                            '"Single parameters to new() must be a HASH ref"',
                            'data => $_[0]',
                        ) . ';',
                    '}',
                    '$params = { %{ $_[0] } };',
                '}',
                'elsif (@_ % 2) {',
                    'Carp::carp(',
                        '"The new() method for ' . $class . ' expects a '
                      . 'hash reference or a key/value list. You passed an '
                      . 'odd number of arguments"',
                    ');',
                    '$params = {@_, undef};',
                '}',
                'else {',
                    '$params = {@_};',
                '}',
                '$params;',
            '}',
        );
    }
    else {
        return $class . '->BUILDARGS(' . $args . ')';
    }
}

sub _inline_slot_initializer {
    my $self  = shift;
    my ($attr, $idx) = @_;

    return (
        '## ' . $attr->name,
        $self->_inline_check_required_attr($attr),
        $self->SUPER::_inline_slot_initializer(@_),
    );
}

sub _inline_check_required_attr {
    my $self = shift;
    my ($attr) = @_;

    return unless defined $attr->init_arg;
    return unless $attr->can('is_required') && $attr->is_required;
    return if $attr->has_default || $attr->has_builder;

    return (
        'if (!exists $params->{\'' . $attr->init_arg . '\'}) {',
            $self->_inline_throw_error(
                '"Attribute (' . quotemeta($attr->name) . ') is required"'
            ) . ';',
        '}',
    );
}

# XXX: these two are duplicated from cmop, because we have to pass the tc stuff
# through to _inline_set_value - this should probably be fixed, but i'm not
# quite sure how. -doy
sub _inline_init_attr_from_constructor {
    my $self = shift;
    my ($attr, $idx) = @_;

    my @initial_value = $attr->_inline_set_value(
        '$instance',
        '$params->{\'' . $attr->init_arg . '\'}',
        '$type_constraint_bodies[' . $idx . ']',
        '$type_coercions[' . $idx . ']',
        '$type_constraint_messages[' . $idx . ']',
        'for constructor',
    );

    push @initial_value, (
        '$attrs->[' . $idx . ']->set_initial_value(',
            '$instance,',
            $attr->_inline_instance_get('$instance'),
        ');',
    ) if $attr->has_initializer;

    return @initial_value;
}

sub _inline_init_attr_from_default {
    my $self = shift;
    my ($attr, $idx) = @_;

    return if $attr->can('is_lazy') && $attr->is_lazy;
    my $default = $self->_inline_default_value($attr, $idx);
    return unless $default;

    my @initial_value = (
        'my $default = ' . $default . ';',
        $attr->_inline_set_value(
            '$instance',
            '$default',
            '$type_constraint_bodies[' . $idx . ']',
            '$type_coercions[' . $idx . ']',
            '$type_constraint_messages[' . $idx . ']',
            'for constructor',
        ),
    );

    push @initial_value, (
        '$attrs->[' . $idx . ']->set_initial_value(',
            '$instance,',
            $attr->_inline_instance_get('$instance'),
        ');',
    ) if $attr->has_initializer;

    return @initial_value;
}

sub _inline_extra_init {
    my $self = shift;
    return (
        $self->_inline_triggers,
        $self->_inline_BUILDALL,
    );
}

sub _inline_triggers {
    my $self = shift;
    my @trigger_calls;

    my @attrs = sort { $a->name cmp $b->name } $self->get_all_attributes;
    for my $i (0 .. $#attrs) {
        my $attr = $attrs[$i];

        next unless $attr->can('has_trigger') && $attr->has_trigger;

        my $init_arg = $attr->init_arg;
        next unless defined $init_arg;

        push @trigger_calls,
            'if (exists $params->{\'' . $init_arg . '\'}) {',
                '$triggers->[' . $i . ']->(',
                    '$instance,',
                    $attr->_inline_instance_get('$instance') . ',',
                ');',
            '}';
    }

    return @trigger_calls;
}

sub _inline_BUILDALL {
    my $self = shift;

    my @methods = reverse $self->find_all_methods_by_name('BUILD');
    my @BUILD_calls;

    foreach my $method (@methods) {
        push @BUILD_calls,
            '$instance->' . $method->{class} . '::BUILD($params);';
    }

    return @BUILD_calls;
}

sub _eval_environment {
    my $self = shift;

    my @attrs = sort { $a->name cmp $b->name } $self->get_all_attributes;

    my $triggers = [
        map { $_->can('has_trigger') && $_->has_trigger ? $_->trigger : undef }
            @attrs
    ];

    # We need to check if the attribute ->can('type_constraint')
    # since we may be trying to immutabilize a Moose meta class,
    # which in turn has attributes which are Class::MOP::Attribute
    # objects, rather than Moose::Meta::Attribute. And
    # Class::MOP::Attribute attributes have no type constraints.
    # However we need to make sure we leave an undef value there
    # because the inlined code is using the index of the attributes
    # to determine where to find the type constraint

    my @type_constraints = map {
        $_->can('type_constraint') ? $_->type_constraint : undef
    } @attrs;

    my @type_constraint_bodies = map {
        defined $_ ? $_->_compiled_type_constraint : undef;
    } @type_constraints;

    my @type_coercions = map {
        defined $_ && $_->has_coercion
            ? $_->coercion->_compiled_type_coercion
            : undef
    } @type_constraints;

    my @type_constraint_messages = map {
        defined $_
            ? ($_->has_message ? $_->message : $_->_default_message)
            : undef
    } @type_constraints;

    return {
        %{ $self->SUPER::_eval_environment },
        ((any { defined && $_->has_initializer } @attrs)
            ? ('$attrs' => \[@attrs])
            : ()),
        '$triggers' => \$triggers,
        '@type_coercions' => \@type_coercions,
        '@type_constraint_bodies' => \@type_constraint_bodies,
        '@type_constraint_messages' => \@type_constraint_messages,
        ( map { defined($_) ? %{ $_->inline_environment } : () }
              @type_constraints ),
        # pretty sure this is only going to be closed over if you use a custom
        # error class at this point, but we should still get rid of this
        # at some point
        '$meta'  => \$self,
    };
}

sub superclasses {
    my $self = shift;
    my $supers = Data::OptList::mkopt(\@_);
    foreach my $super (@{ $supers }) {
        my ($name, $opts) = @{ $super };
        load_class($name, $opts);
        my $meta = Class::MOP::class_of($name);
        $self->throw_error("You cannot inherit from a Moose Role ($name)")
            if $meta && $meta->isa('Moose::Meta::Role')
    }
    return $self->SUPER::superclasses(map { $_->[0] } @{ $supers });
}

### ---------------------------------------------

sub add_attribute {
    my $self = shift;
    my $attr =
        (blessed $_[0] && $_[0]->isa('Class::MOP::Attribute')
            ? $_[0]
            : $self->_process_attribute(@_));
    $self->SUPER::add_attribute($attr);
    # it may be a Class::MOP::Attribute, theoretically, which doesn't have
    # 'bare' and doesn't implement this method
    if ($attr->can('_check_associated_methods')) {
        $attr->_check_associated_methods;
    }
    return $attr;
}

sub add_override_method_modifier {
    my ($self, $name, $method, $_super_package) = @_;

    (!$self->has_method($name))
        || $self->throw_error("Cannot add an override method if a local method is already present");

    $self->add_method($name => Moose::Meta::Method::Overridden->new(
        method  => $method,
        class   => $self,
        package => $_super_package, # need this for roles
        name    => $name,
    ));
}

sub add_augment_method_modifier {
    my ($self, $name, $method) = @_;
    (!$self->has_method($name))
        || $self->throw_error("Cannot add an augment method if a local method is already present");

    $self->add_method($name => Moose::Meta::Method::Augmented->new(
        method  => $method,
        class   => $self,
        name    => $name,
    ));
}

## Private Utility methods ...

sub _find_next_method_by_name_which_is_not_overridden {
    my ($self, $name) = @_;
    foreach my $method ($self->find_all_methods_by_name($name)) {
        return $method->{code}
            if blessed($method->{code}) && !$method->{code}->isa('Moose::Meta::Method::Overridden');
    }
    return undef;
}

## Metaclass compatibility

sub _base_metaclasses {
    my $self = shift;
    my %metaclasses = $self->SUPER::_base_metaclasses;
    for my $class (keys %metaclasses) {
        $metaclasses{$class} =~ s/^Class::MOP/Moose::Meta/;
    }
    return (
        %metaclasses,
        error_class => 'Moose::Error::Default',
    );
}

sub _fix_class_metaclass_incompatibility {
    my $self = shift;
    my ($super_meta) = @_;

    $self->SUPER::_fix_class_metaclass_incompatibility(@_);

    if ($self->_class_metaclass_can_be_made_compatible($super_meta)) {
        ($self->is_pristine)
            || confess "Can't fix metaclass incompatibility for "
                     . $self->name
                     . " because it is not pristine.";
        my $super_meta_name = $super_meta->_real_ref_name;
        my $class_meta_subclass_meta_name = Moose::Util::_reconcile_roles_for_metaclass(blessed($self), $super_meta_name);
        my $new_self = $class_meta_subclass_meta_name->reinitialize(
            $self->name,
        );

        $self->_replace_self( $new_self, $class_meta_subclass_meta_name );
    }
}

sub _fix_single_metaclass_incompatibility {
    my $self = shift;
    my ($metaclass_type, $super_meta) = @_;

    $self->SUPER::_fix_single_metaclass_incompatibility(@_);

    if ($self->_single_metaclass_can_be_made_compatible($super_meta, $metaclass_type)) {
        ($self->is_pristine)
            || confess "Can't fix metaclass incompatibility for "
                     . $self->name
                     . " because it is not pristine.";
        my $super_meta_name = $super_meta->_real_ref_name;
        my $class_specific_meta_subclass_meta_name = Moose::Util::_reconcile_roles_for_metaclass($self->$metaclass_type, $super_meta->$metaclass_type);
        my $new_self = $super_meta->reinitialize(
            $self->name,
            $metaclass_type => $class_specific_meta_subclass_meta_name,
        );

        $self->_replace_self( $new_self, $super_meta_name );
    }
}

sub _replace_self {
    my $self      = shift;
    my ( $new_self, $new_class)   = @_;

    %$self = %$new_self;
    bless $self, $new_class;

    # We need to replace the cached metaclass instance or else when it goes
    # out of scope Class::MOP::Class destroy's the namespace for the
    # metaclass's class, causing much havoc.
    my $weaken = Class::MOP::metaclass_is_weak( $self->name );
    Class::MOP::store_metaclass_by_name( $self->name, $self );
    Class::MOP::weaken_metaclass( $self->name ) if $weaken;
}

sub _process_attribute {
    my ( $self, $name, @args ) = @_;

    @args = %{$args[0]} if scalar @args == 1 && ref($args[0]) eq 'HASH';

    if (($name || '') =~ /^\+(.*)/) {
        return $self->_process_inherited_attribute($1, @args);
    }
    else {
        return $self->_process_new_attribute($name, @args);
    }
}

sub _process_new_attribute {
    my ( $self, $name, @args ) = @_;

    $self->attribute_metaclass->interpolate_class_and_new($name, @args);
}

sub _process_inherited_attribute {
    my ($self, $attr_name, %options) = @_;
    my $inherited_attr = $self->find_attribute_by_name($attr_name);
    (defined $inherited_attr)
        || $self->throw_error("Could not find an attribute by the name of '$attr_name' to inherit from in ${\$self->name}", data => $attr_name);
    if ($inherited_attr->isa('Moose::Meta::Attribute')) {
        return $inherited_attr->clone_and_inherit_options(%options);
    }
    else {
        # NOTE:
        # kind of a kludge to handle Class::MOP::Attributes
        return $inherited_attr->Moose::Meta::Attribute::clone_and_inherit_options(%options);
    }
}

# reinitialization support

sub _restore_metaobjects_from {
    my $self = shift;
    my ($old_meta) = @_;

    $self->SUPER::_restore_metaobjects_from($old_meta);

    for my $role ( @{ $old_meta->roles } ) {
        $self->add_role($role);
    }

    for my $application ( @{ $old_meta->_get_role_applications } ) {
        $application->class($self);
        $self->add_role_application ($application);
    }
}

## Immutability

sub _immutable_options {
    my ( $self, @args ) = @_;

    $self->SUPER::_immutable_options(
        inline_destructor => 1,

        # Moose always does this when an attribute is created
        inline_accessors => 0,

        @args,
    );
}

sub _fixup_attributes_after_rebless {
    my $self = shift;
    my ($instance, $rebless_from, %params) = @_;

    $self->SUPER::_fixup_attributes_after_rebless(
        $instance,
        $rebless_from,
        %params
    );

    $self->_call_all_triggers( $instance, \%params );
}

## -------------------------------------------------

our $error_level;

sub throw_error {
    my ( $self, @args ) = @_;
    local $error_level = ($error_level || 0) + 1;
    $self->raise_error($self->create_error(@args));
}

sub _inline_throw_error {
    my ( $self, @args ) = @_;
    $self->_inline_raise_error($self->_inline_create_error(@args));
}

sub raise_error {
    my ( $self, @args ) = @_;
    die @args;
}

sub _inline_raise_error {
    my ( $self, $message ) = @_;

    return 'die ' . $message;
}

sub create_error {
    my ( $self, @args ) = @_;

    require Carp::Heavy;

    local $error_level = ($error_level || 0 ) + 1;

    if ( @args % 2 == 1 ) {
        unshift @args, "message";
    }

    my %args = ( metaclass => $self, last_error => $@, @args );

    $args{depth} += $error_level;

    my $class = ref $self ? $self->error_class : "Moose::Error::Default";

    load_class($class);

    $class->new(
        Carp::caller_info($args{depth}),
        %args
    );
}

sub _inline_create_error {
    my ( $self, $msg, $args ) = @_;
    # XXX ignore $args for now, nothing currently uses it anyway

    require Carp::Heavy;

    my %args = (
        metaclass  => $self,
        last_error => $@,
        message    => $msg,
    );

    my $class = ref $self ? $self->error_class : "Moose::Error::Default";

    load_class($class);

    # don't check inheritance here - the intention is that the class needs
    # to provide a non-inherited inlining method, because falling back to
    # the default inlining method is most likely going to be wrong
    # yes, this is a huge hack, but so is the entire error system, so.
    return
          '$meta->create_error('
        . $msg
        . ( defined $args ? ', ' . $args : q{} ) . ');'
        unless $class->meta->has_method('_inline_new');

    $class->_inline_new(
        # XXX ignore this for now too
        # Carp::caller_info($args{depth}),
        %args
    );
}

1;

# ABSTRACT: The Moose metaclass

__END__

=pod

=head1 NAME

Moose::Meta::Class - The Moose metaclass

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Class> that provides
additional Moose-specific functionality.

To really understand this class, you will need to start with the
L<Class::MOP::Class> documentation. This class can be understood as a
set of additional features on top of the basic feature provided by
that parent class.

=head1 INHERITANCE

C<Moose::Meta::Class> is a subclass of L<Class::MOP::Class>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::Class->initialize($package_name, %options) >>

This overrides the parent's method in order to provide its own
defaults for the C<attribute_metaclass>, C<instance_metaclass>, and
C<method_metaclass> options.

These all default to the appropriate Moose class.

=item B<< Moose::Meta::Class->create($package_name, %options) >>

This overrides the parent's method in order to accept a C<roles>
option. This should be an array reference containing roles
that the class does, each optionally followed by a hashref of options
(C<-excludes> and C<-alias>).

  my $metaclass = Moose::Meta::Class->create( 'New::Class', roles => [...] );

=item B<< Moose::Meta::Class->create_anon_class >>

This overrides the parent's method to accept a C<roles> option, just
as C<create> does.

It also accepts a C<cache> option. If this is true, then the anonymous
class will be cached based on its superclasses and roles. If an
existing anonymous class in the cache has the same superclasses and
roles, it will be reused.

  my $metaclass = Moose::Meta::Class->create_anon_class(
      superclasses => ['Foo'],
      roles        => [qw/Some Roles Go Here/],
      cache        => 1,
  );

Each entry in both the C<superclasses> and the C<roles> option can be
followed by a hash reference with arguments. The C<superclasses>
option can be supplied with a L<-version|Class::MOP/Class Loading
Options> option that ensures the loaded superclass satisfies the
required version. The C<role> option also takes the C<-version> as an
argument, but the option hash reference can also contain any other
role relevant values like exclusions or parameterized role arguments.

=item B<< $metaclass->new_object(%params) >>

This overrides the parent's method in order to add support for
attribute triggers.

=item B<< $metaclass->superclasses(@superclasses) >>

This is the accessor allowing you to read or change the parents of
the class.

Each superclass can be followed by a hash reference containing a
L<-version|Class::MOP/Class Loading Options> value. If the version
requirement is not satisfied an error will be thrown.

=item B<< $metaclass->add_override_method_modifier($name, $sub) >>

This adds an C<override> method modifier to the package.

=item B<< $metaclass->add_augment_method_modifier($name, $sub) >>

This adds an C<augment> method modifier to the package.

=item B<< $metaclass->calculate_all_roles >>

This will return a unique array of C<Moose::Meta::Role> instances
which are attached to this class.

=item B<< $metaclass->calculate_all_roles_with_inheritance >>

This will return a unique array of C<Moose::Meta::Role> instances
which are attached to this class, and each of this class's ancestors.

=item B<< $metaclass->add_role($role) >>

This takes a L<Moose::Meta::Role> object, and adds it to the class's
list of roles. This I<does not> actually apply the role to the class.

=item B<< $metaclass->role_applications >>

Returns a list of L<Moose::Meta::Role::Application::ToClass>
objects, which contain the arguments to role application.

=item B<< $metaclass->add_role_application($application) >>

This takes a L<Moose::Meta::Role::Application::ToClass> object, and
adds it to the class's list of role applications. This I<does not>
actually apply any role to the class; it is only for tracking role
applications.

=item B<< $metaclass->does_role($role) >>

This returns a boolean indicating whether or not the class does the specified
role. The role provided can be either a role name or a L<Moose::Meta::Role>
object. This tests both the class and its parents.

=item B<< $metaclass->excludes_role($role_name) >>

A class excludes a role if it has already composed a role which
excludes the named role. This tests both the class and its parents.

=item B<< $metaclass->add_attribute($attr_name, %params|$params) >>

This overrides the parent's method in order to allow the parameters to
be provided as a hash reference.

=item B<< $metaclass->constructor_class($class_name) >>

=item B<< $metaclass->destructor_class($class_name) >>

These are the names of classes used when making a class immutable. These
default to L<Moose::Meta::Method::Constructor> and
L<Moose::Meta::Method::Destructor> respectively. These accessors are
read-write, so you can use them to change the class name.

=item B<< $metaclass->error_class($class_name) >>

The name of the class used to throw errors. This defaults to
L<Moose::Error::Default>, which generates an error with a stacktrace
just like C<Carp::confess>.

=item B<< $metaclass->throw_error($message, %extra) >>

Throws the error created by C<create_error> using C<raise_error>

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
