package Moose::Meta::Role;
BEGIN {
  $Moose::Meta::Role::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Role::VERSION = '2.1005';
}

use strict;
use warnings;
use metaclass;

use Class::Load qw(load_class);
use Scalar::Util 'blessed';
use Carp         'confess';
use Devel::GlobalDestruction 'in_global_destruction';

use Moose::Meta::Class;
use Moose::Meta::Role::Attribute;
use Moose::Meta::Role::Method;
use Moose::Meta::Role::Method::Required;
use Moose::Meta::Role::Method::Conflicting;
use Moose::Meta::Method::Meta;
use Moose::Util qw( ensure_all_roles );
use Class::MOP::MiniTrait;

use base 'Class::MOP::Module',
         'Class::MOP::Mixin::HasAttributes',
         'Class::MOP::Mixin::HasMethods';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

## ------------------------------------------------------------------
## NOTE:
## I normally don't do this, but I am doing
## a whole bunch of meta-programmin' in this
## module, so it just makes sense. For a clearer
## picture of what is going on in the next
## several lines of code, look at the really
## big comment at the end of this file (right
## before the POD).
## - SL
## ------------------------------------------------------------------

my $META = __PACKAGE__->meta;

## ------------------------------------------------------------------
## attributes ...

# NOTE:
# since roles are lazy, we hold all the attributes
# of the individual role in 'stasis' until which
# time when it is applied to a class. This means
# keeping a lot of things in hash maps, so we are
# using a little of that meta-programmin' magic
# here and saving lots of extra typin'. And since
# many of these attributes above require similar
# functionality to support them, so we again use
# the wonders of meta-programmin' to deliver a
# very compact solution to this normally verbose
# problem.
# - SL

foreach my $action (
    {
        name        => 'excluded_roles_map',
        attr_reader => 'get_excluded_roles_map' ,
        methods     => {
            add       => 'add_excluded_roles',
            get_keys  => 'get_excluded_roles_list',
            existence => 'excludes_role',
        }
    },
    {
        name        => 'required_methods',
        attr_reader => 'get_required_methods_map',
        methods     => {
            remove     => 'remove_required_methods',
            get_values => 'get_required_method_list',
            existence  => 'requires_method',
        }
    },
) {

    my $attr_reader = $action->{attr_reader};
    my $methods     = $action->{methods};

    # create the attribute
    $META->add_attribute($action->{name} => (
        reader  => $attr_reader,
        default => sub { {} },
        Class::MOP::_definition_context(),
    ));

    # create some helper methods
    $META->add_method($methods->{add} => sub {
        my ($self, @values) = @_;
        $self->$attr_reader->{$_} = undef foreach @values;
    }) if exists $methods->{add};

    $META->add_method($methods->{get_keys} => sub {
        my ($self) = @_;
        keys %{$self->$attr_reader};
    }) if exists $methods->{get_keys};

    $META->add_method($methods->{get_values} => sub {
        my ($self) = @_;
        values %{$self->$attr_reader};
    }) if exists $methods->{get_values};

    $META->add_method($methods->{get} => sub {
        my ($self, $name) = @_;
        $self->$attr_reader->{$name}
    }) if exists $methods->{get};

    $META->add_method($methods->{existence} => sub {
        my ($self, $name) = @_;
        exists $self->$attr_reader->{$name} ? 1 : 0;
    }) if exists $methods->{existence};

    $META->add_method($methods->{remove} => sub {
        my ($self, @values) = @_;
        delete $self->$attr_reader->{$_} foreach @values;
    }) if exists $methods->{remove};
}

$META->add_attribute(
    'method_metaclass',
    reader  => 'method_metaclass',
    default => 'Moose::Meta::Role::Method',
    Class::MOP::_definition_context(),
);

$META->add_attribute(
    'required_method_metaclass',
    reader  => 'required_method_metaclass',
    default => 'Moose::Meta::Role::Method::Required',
    Class::MOP::_definition_context(),
);

$META->add_attribute(
    'conflicting_method_metaclass',
    reader  => 'conflicting_method_metaclass',
    default => 'Moose::Meta::Role::Method::Conflicting',
    Class::MOP::_definition_context(),
);

$META->add_attribute(
    'application_to_class_class',
    reader  => 'application_to_class_class',
    default => 'Moose::Meta::Role::Application::ToClass',
    Class::MOP::_definition_context(),
);

$META->add_attribute(
    'application_to_role_class',
    reader  => 'application_to_role_class',
    default => 'Moose::Meta::Role::Application::ToRole',
    Class::MOP::_definition_context(),
);

$META->add_attribute(
    'application_to_instance_class',
    reader  => 'application_to_instance_class',
    default => 'Moose::Meta::Role::Application::ToInstance',
    Class::MOP::_definition_context(),
);

$META->add_attribute(
    'applied_attribute_metaclass',
    reader  => 'applied_attribute_metaclass',
    default => 'Moose::Meta::Attribute',
    Class::MOP::_definition_context(),
);

# More or less copied from Moose::Meta::Class
sub initialize {
    my $class = shift;
    my @args = @_;
    unshift @args, 'package' if @args % 2;
    my %opts = @args;
    my $package = delete $opts{package};
    return Class::MOP::get_metaclass_by_name($package)
        || $class->SUPER::initialize($package,
                'attribute_metaclass' => 'Moose::Meta::Role::Attribute',
                %opts,
            );
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
            required_method_metaclass
            conflicting_method_metaclass
            application_to_class_class
            application_to_role_class
            application_to_instance_class
            applied_attribute_metaclass
        );
    }

    my %options = @_;
    $options{weaken} = Class::MOP::metaclass_is_weak($meta->name)
        if !exists $options{weaken}
        && blessed($meta)
        && $meta->isa('Moose::Meta::Role');

    # don't need to remove generated metaobjects here yet, since we don't
    # yet generate anything in roles. this may change in the future though...
    # keep an eye on that
    my $new_meta = $self->SUPER::reinitialize(
        $pkg,
        %existing_classes,
        %options,
    );
    $new_meta->_restore_metaobjects_from($meta)
        if $meta && $meta->isa('Moose::Meta::Role');
    return $new_meta;
}

sub _restore_metaobjects_from {
    my $self = shift;
    my ($old_meta) = @_;

    $self->_restore_metamethods_from($old_meta);
    $self->_restore_metaattributes_from($old_meta);

    for my $role ( @{ $old_meta->get_roles } ) {
        $self->add_role($role);
    }
}

sub add_attribute {
    my $self = shift;

    if (blessed $_[0] && ! $_[0]->isa('Moose::Meta::Role::Attribute') ) {
        my $class = ref $_[0];
        Moose->throw_error( "Cannot add a $class as an attribute to a role" );
    }
    elsif (!blessed($_[0]) && defined($_[0]) && $_[0] =~ /^\+(.*)/) {
        Moose->throw_error( "has '+attr' is not supported in roles" );
    }

    return $self->SUPER::add_attribute(@_);
}

sub _attach_attribute {
    my ( $self, $attribute ) = @_;

    $attribute->attach_to_role($self);
}

sub add_required_methods {
    my $self = shift;

    for (@_) {
        my $method = $_;
        if (!blessed($method)) {
            $method = $self->required_method_metaclass->new(
                name => $method,
            );
        }
        $self->get_required_methods_map->{$method->name} = $method;
    }
}

sub add_conflicting_method {
    my $self = shift;

    my $method;
    if (@_ == 1 && blessed($_[0])) {
        $method = shift;
    }
    else {
        $method = $self->conflicting_method_metaclass->new(@_);
    }

    $self->add_required_methods($method);
}

## ------------------------------------------------------------------
## method modifiers

# NOTE:
# the before/around/after method modifiers are
# stored by name, but there can be many methods
# then associated with that name. So again we have
# lots of similar functionality, so we can do some
# meta-programmin' and save some time.
# - SL

foreach my $modifier_type (qw[ before around after ]) {

    my $attr_reader = "get_${modifier_type}_method_modifiers_map";

    # create the attribute ...
    $META->add_attribute("${modifier_type}_method_modifiers" => (
        reader  => $attr_reader,
        default => sub { {} },
        Class::MOP::_definition_context(),
    ));

    # and some helper methods ...
    $META->add_method("get_${modifier_type}_method_modifiers" => sub {
        my ($self, $method_name) = @_;
        #return () unless exists $self->$attr_reader->{$method_name};
        my $mm = $self->$attr_reader->{$method_name};
        $mm ? @$mm : ();
    });

    $META->add_method("has_${modifier_type}_method_modifiers" => sub {
        my ($self, $method_name) = @_;
        # NOTE:
        # for now we assume that if it exists,..
        # it has at least one modifier in it
        (exists $self->$attr_reader->{$method_name}) ? 1 : 0;
    });

    $META->add_method("add_${modifier_type}_method_modifier" => sub {
        my ($self, $method_name, $method) = @_;

        $self->$attr_reader->{$method_name} = []
            unless exists $self->$attr_reader->{$method_name};

        my $modifiers = $self->$attr_reader->{$method_name};

        # NOTE:
        # check to see that we aren't adding the
        # same code twice. We err in favor of the
        # first on here, this may not be as expected
        foreach my $modifier (@{$modifiers}) {
            return if $modifier == $method;
        }

        push @{$modifiers} => $method;
    });

}

## ------------------------------------------------------------------
## override method modifiers

$META->add_attribute('override_method_modifiers' => (
    reader  => 'get_override_method_modifiers_map',
    default => sub { {} },
    Class::MOP::_definition_context(),
));

# NOTE:
# these are a little different because there
# can only be one per name, whereas the other
# method modifiers can have multiples.
# - SL

sub add_override_method_modifier {
    my ($self, $method_name, $method) = @_;
    (!$self->has_method($method_name))
        || Moose->throw_error("Cannot add an override of method '$method_name' " .
                   "because there is a local version of '$method_name'");
    $self->get_override_method_modifiers_map->{$method_name} = $method;
}

sub has_override_method_modifier {
    my ($self, $method_name) = @_;
    # NOTE:
    # for now we assume that if it exists,..
    # it has at least one modifier in it
    (exists $self->get_override_method_modifiers_map->{$method_name}) ? 1 : 0;
}

sub get_override_method_modifier {
    my ($self, $method_name) = @_;
    $self->get_override_method_modifiers_map->{$method_name};
}

## general list accessor ...

sub get_method_modifier_list {
    my ($self, $modifier_type) = @_;
    my $accessor = "get_${modifier_type}_method_modifiers_map";
    keys %{$self->$accessor};
}

sub _meta_method_class { 'Moose::Meta::Method::Meta' }

## ------------------------------------------------------------------
## subroles

$META->add_attribute('roles' => (
    reader  => 'get_roles',
    default => sub { [] },
    Class::MOP::_definition_context(),
));

sub add_role {
    my ($self, $role) = @_;
    (blessed($role) && $role->isa('Moose::Meta::Role'))
        || Moose->throw_error("Roles must be instances of Moose::Meta::Role");
    push @{$self->get_roles} => $role;
    $self->reset_package_cache_flag;
}

sub calculate_all_roles {
    my $self = shift;
    my %seen;
    grep {
        !$seen{$_->name}++
    } ($self, map {
                  $_->calculate_all_roles
              } @{ $self->get_roles });
}

sub does_role {
    my ($self, $role) = @_;
    (defined $role)
        || Moose->throw_error("You must supply a role name to look for");
    my $role_name = blessed $role ? $role->name : $role;
    # if we are it,.. then return true
    return 1 if $role_name eq $self->name;
    # otherwise.. check our children
    foreach my $role (@{$self->get_roles}) {
        return 1 if $role->does_role($role_name);
    }
    return 0;
}

sub find_method_by_name { (shift)->get_method(@_) }

## ------------------------------------------------------------------
## role construction
## ------------------------------------------------------------------

sub apply {
    my ($self, $other, %args) = @_;

    (blessed($other))
        || Moose->throw_error("You must pass in an blessed instance");

    my $application_class;
    if ($other->isa('Moose::Meta::Role')) {
        $application_class = $self->application_to_role_class;
    }
    elsif ($other->isa('Moose::Meta::Class')) {
        $application_class = $self->application_to_class_class;
    }
    else {
        $application_class = $self->application_to_instance_class;
    }

    load_class($application_class);

    if ( exists $args{'-excludes'} ) {
        # I wish we had coercion here :)
        $args{'-excludes'} = (
            ref $args{'-excludes'} eq 'ARRAY'
            ? $args{'-excludes'}
            : [ $args{'-excludes'} ]
        );
    }

    return $application_class->new(%args)->apply($self, $other, \%args);
}

sub composition_class_roles { }

sub combine {
    my ($class, @role_specs) = @_;

    require Moose::Meta::Role::Composite;

    my (@roles, %role_params);
    while (@role_specs) {
        my ($role, $params) = @{ splice @role_specs, 0, 1 };
        my $requested_role
            = blessed $role
            ? $role
            : Class::MOP::class_of($role);

        my $actual_role = $requested_role->_role_for_combination($params);
        push @roles => $actual_role;

        next unless defined $params;
        $role_params{$actual_role->name} = $params;
    }

    my $c = Moose::Meta::Role::Composite->new(roles => \@roles);
    return $c->apply_params(\%role_params);
}

sub _role_for_combination {
    my ($self, $params) = @_;
    return $self;
}

sub create {
    my $class = shift;
    my @args = @_;

    unshift @args, 'package' if @args % 2 == 1;
    my %options = @args;

    (ref $options{attributes} eq 'HASH')
        || confess "You must pass a HASH ref of attributes"
            if exists $options{attributes};

    (ref $options{methods} eq 'HASH')
        || confess "You must pass a HASH ref of methods"
            if exists $options{methods};

    (ref $options{roles} eq 'ARRAY')
        || confess "You must pass an ARRAY ref of roles"
            if exists $options{roles};

    my $package      = delete $options{package};
    my $roles        = delete $options{roles};
    my $attributes   = delete $options{attributes};
    my $methods      = delete $options{methods};
    my $meta_name    = exists $options{meta_name}
                         ? delete $options{meta_name}
                         : 'meta';

    my $meta = $class->SUPER::create($package => %options);

    $meta->_add_meta_method($meta_name)
        if defined $meta_name;

    if (defined $attributes) {
        foreach my $attribute_name (keys %{$attributes}) {
            my $attr = $attributes->{$attribute_name};
            $meta->add_attribute(
                $attribute_name => blessed $attr ? $attr : %{$attr} );
        }
    }

    if (defined $methods) {
        foreach my $method_name (keys %{$methods}) {
            $meta->add_method($method_name, $methods->{$method_name});
        }
    }

    if ($roles) {
        Moose::Util::apply_all_roles($meta, @$roles);
    }

    return $meta;
}

sub consumers {
    my $self = shift;
    my @consumers;
    for my $meta (Class::MOP::get_all_metaclass_instances) {
        next if $meta->name eq $self->name;
        next unless $meta->isa('Moose::Meta::Class')
                 || $meta->isa('Moose::Meta::Role');
        push @consumers, $meta->name
            if $meta->does_role($self->name);
    }
    return @consumers;
}

# XXX: something more intelligent here?
sub _anon_package_prefix { 'Moose::Meta::Role::__ANON__::SERIAL::' }

sub create_anon_role { shift->create_anon(@_) }
sub is_anon_role     { shift->is_anon(@_)     }

sub _anon_cache_key {
    my $class = shift;
    my %options = @_;

    # XXX fix this duplication (see MMC::_anon_cache_key
    my $roles = Data::OptList::mkopt(($options{roles} || []), {
        moniker  => 'role',
        val_test => sub { ref($_[0]) eq 'HASH' },
    });

    my @role_keys;
    for my $role_spec (@$roles) {
        my ($role, $params) = @$role_spec;
        $params = { %$params };

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

    # Makes something like Role|Role::1
    return join('|', sort @role_keys);
}

#####################################################################
## NOTE:
## This is Moose::Meta::Role as defined by Moose (plus the use of
## MooseX::AttributeHelpers module). It is here as a reference to
## make it easier to see what is happening above with all the meta
## programming. - SL
#####################################################################
#
# has 'roles' => (
#     metaclass => 'Array',
#     reader    => 'get_roles',
#     isa       => 'ArrayRef[Moose::Meta::Role]',
#     default   => sub { [] },
#     provides  => {
#         'push' => 'add_role',
#     }
# );
#
# has 'excluded_roles_map' => (
#     metaclass => 'Hash',
#     reader    => 'get_excluded_roles_map',
#     isa       => 'HashRef[Str]',
#     provides  => {
#         # Not exactly set, cause it sets multiple
#         'set'    => 'add_excluded_roles',
#         'keys'   => 'get_excluded_roles_list',
#         'exists' => 'excludes_role',
#     }
# );
#
# has 'required_methods' => (
#     metaclass => 'Hash',
#     reader    => 'get_required_methods_map',
#     isa       => 'HashRef[Moose::Meta::Role::Method::Required]',
#     provides  => {
#         # not exactly set, or delete since it works for multiple
#         'set'    => 'add_required_methods',
#         'delete' => 'remove_required_methods',
#         'keys'   => 'get_required_method_list',
#         'exists' => 'requires_method',
#     }
# );
#
# # the before, around and after modifiers are
# # HASH keyed by method-name, with ARRAY of
# # CODE refs to apply in that order
#
# has 'before_method_modifiers' => (
#     metaclass => 'Hash',
#     reader    => 'get_before_method_modifiers_map',
#     isa       => 'HashRef[ArrayRef[CodeRef]]',
#     provides  => {
#         'keys'   => 'get_before_method_modifiers',
#         'exists' => 'has_before_method_modifiers',
#         # This actually makes sure there is an
#         # ARRAY at the given key, and pushed onto
#         # it. It also checks for duplicates as well
#         # 'add'  => 'add_before_method_modifier'
#     }
# );
#
# has 'after_method_modifiers' => (
#     metaclass => 'Hash',
#     reader    =>'get_after_method_modifiers_map',
#     isa       => 'HashRef[ArrayRef[CodeRef]]',
#     provides  => {
#         'keys'   => 'get_after_method_modifiers',
#         'exists' => 'has_after_method_modifiers',
#         # This actually makes sure there is an
#         # ARRAY at the given key, and pushed onto
#         # it. It also checks for duplicates as well
#         # 'add'  => 'add_after_method_modifier'
#     }
# );
#
# has 'around_method_modifiers' => (
#     metaclass => 'Hash',
#     reader    =>'get_around_method_modifiers_map',
#     isa       => 'HashRef[ArrayRef[CodeRef]]',
#     provides  => {
#         'keys'   => 'get_around_method_modifiers',
#         'exists' => 'has_around_method_modifiers',
#         # This actually makes sure there is an
#         # ARRAY at the given key, and pushed onto
#         # it. It also checks for duplicates as well
#         # 'add'  => 'add_around_method_modifier'
#     }
# );
#
# # override is similar to the other modifiers
# # except that it is not an ARRAY of code refs
# # but instead just a single name->code mapping
#
# has 'override_method_modifiers' => (
#     metaclass => 'Hash',
#     reader    =>'get_override_method_modifiers_map',
#     isa       => 'HashRef[CodeRef]',
#     provides  => {
#         'keys'   => 'get_override_method_modifier',
#         'exists' => 'has_override_method_modifier',
#         'add'    => 'add_override_method_modifier', # checks for local method ..
#     }
# );
#
#####################################################################


1;

# ABSTRACT: The Moose Role metaclass

__END__

=pod

=head1 NAME

Moose::Meta::Role - The Moose Role metaclass

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Module> that provides
additional Moose-specific functionality.

Its API looks a lot like L<Moose::Meta::Class>, but internally it
implements many things differently. This may change in the future.

=head1 INHERITANCE

C<Moose::Meta::Role> is a subclass of L<Class::MOP::Module>.

=head1 METHODS

=head2 Construction

=over 4

=item B<< Moose::Meta::Role->initialize($role_name) >>

This method creates a new role object with the provided name.

=item B<< Moose::Meta::Role->combine( [ $role => { ... } ], [ $role ], ... ) >>

This method accepts a list of array references. Each array reference
should contain a role name or L<Moose::Meta::Role> object as its first element. The second element is
an optional hash reference. The hash reference can contain C<-excludes>
and C<-alias> keys to control how methods are composed from the role.

The return value is a new L<Moose::Meta::Role::Composite> that
represents the combined roles.

=item B<< $metarole->composition_class_roles >>

When combining multiple roles using C<combine>, this method is used to obtain a
list of role names to be applied to the L<Moose::Meta::Role::Composite>
instance returned by C<combine>. The default implementation returns an empty
list. Extensions that need to hook into role combination may wrap this method
to return additional role names.

=item B<< Moose::Meta::Role->create($name, %options) >>

This method is identical to the L<Moose::Meta::Class> C<create>
method.

=item B<< Moose::Meta::Role->create_anon_role >>

This method is identical to the L<Moose::Meta::Class>
C<create_anon_class> method.

=item B<< $metarole->is_anon_role >>

Returns true if the role is an anonymous role.

=item B<< $metarole->consumers >>

Returns a list of names of classes and roles which consume this role.

=back

=head2 Role application

=over 4

=item B<< $metarole->apply( $thing, @options ) >>

This method applies a role to the given C<$thing>. That can be another
L<Moose::Meta::Role>, object, a L<Moose::Meta::Class> object, or a
(non-meta) object instance.

The options are passed directly to the constructor for the appropriate
L<Moose::Meta::Role::Application> subclass.

Note that this will apply the role even if the C<$thing> in question already
C<does> this role.  L<Moose::Util/does_role> is a convenient wrapper for
finding out if role application is necessary.

=back

=head2 Roles and other roles

=over 4

=item B<< $metarole->get_roles >>

This returns an array reference of roles which this role does. This
list may include duplicates.

=item B<< $metarole->calculate_all_roles >>

This returns a I<unique> list of all roles that this role does, and
all the roles that its roles do.

=item B<< $metarole->does_role($role) >>

Given a role I<name> or L<Moose::Meta::Role> object, returns true if this role
does the given role.

=item B<< $metarole->add_role($role) >>

Given a L<Moose::Meta::Role> object, this adds the role to the list of
roles that the role does.

=item B<< $metarole->get_excluded_roles_list >>

Returns a list of role names which this role excludes.

=item B<< $metarole->excludes_role($role_name) >>

Given a role I<name>, returns true if this role excludes the named
role.

=item B<< $metarole->add_excluded_roles(@role_names) >>

Given one or more role names, adds those roles to the list of excluded
roles.

=back

=head2 Methods

The methods for dealing with a role's methods are all identical in API
and behavior to the same methods in L<Class::MOP::Class>.

=over 4

=item B<< $metarole->method_metaclass >>

Returns the method metaclass name for the role. This defaults to
L<Moose::Meta::Role::Method>.

=item B<< $metarole->get_method($name) >>

=item B<< $metarole->has_method($name) >>

=item B<< $metarole->add_method( $name, $body ) >>

=item B<< $metarole->get_method_list >>

=item B<< $metarole->find_method_by_name($name) >>

These methods are all identical to the methods of the same name in
L<Class::MOP::Package>

=back

=head2 Attributes

As with methods, the methods for dealing with a role's attribute are
all identical in API and behavior to the same methods in
L<Class::MOP::Class>.

However, attributes stored in this class are I<not> stored as
objects. Rather, the attribute definition is stored as a hash
reference. When a role is composed into a class, this hash reference
is passed directly to the metaclass's C<add_attribute> method.

This is quite likely to change in the future.

=over 4

=item B<< $metarole->get_attribute($attribute_name) >>

=item B<< $metarole->has_attribute($attribute_name) >>

=item B<< $metarole->get_attribute_list >>

=item B<< $metarole->add_attribute($name, %options) >>

=item B<< $metarole->remove_attribute($attribute_name) >>

=back

=head2 Overload introspection and creation

The methods for dealing with a role's overloads are all identical in API
and behavior to the same methods in L<Class::MOP::Class>. Note that these are
not particularly useful (yet), because overloads do not participate in role
composition.

=over 4

=item B<< $metarole->is_overloaded >>

=item B<< $metarole->get_overloaded_operator($op) >>

=item B<< $metarole->has_overloaded_operator($op) >>

=item B<< $metarole->get_overload_list >>

=item B<< $metarole->get_all_overloaded_operators >>

=item B<< $metarole->add_overloaded_operator($op, $impl) >>

=item B<< $metarole->remove_overloaded_operator($op) >>

=back

=head2 Required methods

=over 4

=item B<< $metarole->get_required_method_list >>

Returns the list of methods required by the role.

=item B<< $metarole->requires_method($name) >>

Returns true if the role requires the named method.

=item B<< $metarole->add_required_methods(@names) >>

Adds the named methods to the role's list of required methods.

=item B<< $metarole->remove_required_methods(@names) >>

Removes the named methods from the role's list of required methods.

=item B<< $metarole->add_conflicting_method(%params) >>

Instantiate the parameters as a L<Moose::Meta::Role::Method::Conflicting>
object, then add it to the required method list.

=back

=head2 Method modifiers

These methods act like their counterparts in L<Class::MOP::Class> and
L<Moose::Meta::Class>.

However, method modifiers are simply stored internally, and are not
applied until the role itself is applied to a class.

=over 4

=item B<< $metarole->add_after_method_modifier($method_name, $method) >>

=item B<< $metarole->add_around_method_modifier($method_name, $method) >>

=item B<< $metarole->add_before_method_modifier($method_name, $method) >>

=item B<< $metarole->add_override_method_modifier($method_name, $method) >>

These methods all add an appropriate modifier to the internal list of
modifiers.

=item B<< $metarole->has_after_method_modifiers >>

=item B<< $metarole->has_around_method_modifiers >>

=item B<< $metarole->has_before_method_modifiers >>

=item B<< $metarole->has_override_method_modifier >>

Return true if the role has any modifiers of the given type.

=item B<< $metarole->get_after_method_modifiers($method_name) >>

=item B<< $metarole->get_around_method_modifiers($method_name) >>

=item B<< $metarole->get_before_method_modifiers($method_name) >>

Given a method name, returns a list of the appropriate modifiers for
that method.

=item B<< $metarole->get_override_method_modifier($method_name) >>

Given a method name, returns the override method modifier for that
method, if it has one.

=back

=head2 Introspection

=over 4

=item B<< Moose::Meta::Role->meta >>

This will return a L<Class::MOP::Class> instance for this class.

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
