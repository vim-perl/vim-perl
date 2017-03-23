
package Moose::Meta::Attribute;
BEGIN {
  $Moose::Meta::Attribute::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Attribute::VERSION = '2.1005';
}

use strict;
use warnings;

use B ();
use Class::Load qw(is_class_loaded load_class);
use Scalar::Util 'blessed', 'weaken';
use List::MoreUtils 'any';
use Try::Tiny;
use overload     ();

use Moose::Deprecated;
use Moose::Meta::Method::Accessor;
use Moose::Meta::Method::Delegation;
use Moose::Util ();
use Moose::Util::TypeConstraints ();
use Class::MOP::MiniTrait;

use base 'Class::MOP::Attribute', 'Moose::Meta::Mixin::AttributeCore';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

__PACKAGE__->meta->add_attribute('traits' => (
    reader    => 'applied_traits',
    predicate => 'has_applied_traits',
    Class::MOP::_definition_context(),
));

# we need to have a ->does method in here to
# more easily support traits, and the introspection
# of those traits. We extend the does check to look
# for metatrait aliases.
sub does {
    my ($self, $role_name) = @_;
    my $name = try {
        Moose::Util::resolve_metatrait_alias(Attribute => $role_name)
    };
    return 0 if !defined($name); # failed to load class
    return $self->Moose::Object::does($name);
}

sub _error_thrower {
    my $self = shift;
    require Moose::Meta::Class;
    ( ref $self && $self->associated_class ) || "Moose::Meta::Class";
}

sub throw_error {
    my $self = shift;
    my $inv = $self->_error_thrower;
    unshift @_, "message" if @_ % 2 == 1;
    unshift @_, attr => $self if ref $self;
    unshift @_, $inv;
    my $handler = $inv->can("throw_error"); # to avoid incrementing depth by 1
    goto $handler;
}

sub _inline_throw_error {
    my ( $self, $msg, $args ) = @_;

    my $inv = $self->_error_thrower;
    # XXX ugh
    $inv = 'Moose::Meta::Class' unless $inv->can('_inline_throw_error');

    # XXX ugh ugh UGH
    my $class = $self->associated_class;
    if ($class) {
        my $class_name = B::perlstring($class->name);
        my $attr_name = B::perlstring($self->name);
        $args = 'attr => Class::MOP::class_of(' . $class_name . ')'
              . '->find_attribute_by_name(' . $attr_name . '), '
              . (defined $args ? $args : '');
    }

    return $inv->_inline_throw_error($msg, $args)
}

sub new {
    my ($class, $name, %options) = @_;
    $class->_process_options($name, \%options) unless $options{__hack_no_process_options}; # used from clone()... YECHKKK FIXME ICKY YUCK GROSS

    delete $options{__hack_no_process_options};

    my %attrs =
        ( map { $_ => 1 }
          grep { defined }
          map { $_->init_arg() }
          $class->meta()->get_all_attributes()
        );

    my @bad = sort grep { ! $attrs{$_} }  keys %options;

    if (@bad)
    {
        my $s = @bad > 1 ? 's' : '';
        my $list = join "', '", @bad;

        my $package = $options{definition_context}{package};
        my $context = $options{definition_context}{context}
                   || 'attribute constructor';
        my $type = $options{definition_context}{type} || 'class';

        my $location = '';
        if (defined($package)) {
            $location = " in ";
            $location .= "$type " if $type;
            $location .= $package;
        }

        Carp::cluck "Found unknown argument$s '$list' in the $context for '$name'$location";
    }

    return $class->SUPER::new($name, %options);
}

sub interpolate_class_and_new {
    my ($class, $name, %args) = @_;

    my ( $new_class, @traits ) = $class->interpolate_class(\%args);

    $new_class->new($name, %args, ( scalar(@traits) ? ( traits => \@traits ) : () ) );
}

sub interpolate_class {
    my ($class, $options) = @_;

    $class = ref($class) || $class;

    if ( my $metaclass_name = delete $options->{metaclass} ) {
        my $new_class = Moose::Util::resolve_metaclass_alias( Attribute => $metaclass_name );

        if ( $class ne $new_class ) {
            if ( $new_class->can("interpolate_class") ) {
                return $new_class->interpolate_class($options);
            } else {
                $class = $new_class;
            }
        }
    }

    my @traits;

    if (my $traits = $options->{traits}) {
        my $i = 0;
        my $has_foreign_options = 0;

        while ($i < @$traits) {
            my $trait = $traits->[$i++];
            next if ref($trait); # options to a trait we discarded

            $trait = Moose::Util::resolve_metatrait_alias(Attribute => $trait)
                  || $trait;

            next if $class->does($trait);

            push @traits, $trait;

            # are there options?
            if ($traits->[$i] && ref($traits->[$i])) {
                $has_foreign_options = 1
                    if any { $_ ne '-alias' && $_ ne '-excludes' } keys %{ $traits->[$i] };

                push @traits, $traits->[$i++];
            }
        }

        if (@traits) {
            my %options = (
                superclasses => [ $class ],
                roles        => [ @traits ],
            );

            if ($has_foreign_options) {
                $options{weaken} = 0;
            }
            else {
                $options{cache} = 1;
            }

            my $anon_class = Moose::Meta::Class->create_anon_class(%options);
            $class = $anon_class->name;
        }
    }

    return ( wantarray ? ( $class, @traits ) : $class );
}

# ...

# method-generating options shouldn't be overridden
sub illegal_options_for_inheritance {
    qw(reader writer accessor clearer predicate)
}

# NOTE/TODO
# This method *must* be able to handle
# Class::MOP::Attribute instances as
# well. Yes, I know that is wrong, but
# apparently we didn't realize it was
# doing that and now we have some code
# which is dependent on it. The real
# solution of course is to push this
# feature back up into Class::MOP::Attribute
# but I not right now, I am too lazy.
# However if you are reading this and
# looking for something to do,.. please
# be my guest.
# - stevan
sub clone_and_inherit_options {
    my ($self, %options) = @_;

    # NOTE:
    # we may want to extends a Class::MOP::Attribute
    # in which case we need to be able to use the
    # core set of legal options that have always
    # been here. But we allows Moose::Meta::Attribute
    # instances to changes them.
    # - SL
    my @illegal_options = $self->can('illegal_options_for_inheritance')
        ? $self->illegal_options_for_inheritance
        : ();

    my @found_illegal_options = grep { exists $options{$_} && exists $self->{$_} ? $_ : undef } @illegal_options;
    (scalar @found_illegal_options == 0)
        || $self->throw_error("Illegal inherited options => (" . (join ', ' => @found_illegal_options) . ")", data => \%options);

    $self->_process_isa_option( $self->name, \%options );
    $self->_process_does_option( $self->name, \%options );

    # NOTE:
    # this doesn't apply to Class::MOP::Attributes,
    # so we can ignore it for them.
    # - SL
    if ($self->can('interpolate_class')) {
        ( $options{metaclass}, my @traits ) = $self->interpolate_class(\%options);

        my %seen;
        my @all_traits = grep { $seen{$_}++ } @{ $self->applied_traits || [] }, @traits;
        $options{traits} = \@all_traits if @all_traits;
    }

    # This method can be called on a CMOP::Attribute object, so we need to
    # make sure we can call this method.
    $self->_process_lazy_build_option( $self->name, \%options )
        if $self->can('_process_lazy_build_option');

    $self->clone(%options);
}

sub clone {
    my ( $self, %params ) = @_;

    my $class = delete $params{metaclass} || ref $self;

    my ( @init, @non_init );

    foreach my $attr ( grep { $_->has_value($self) } Class::MOP::class_of($self)->get_all_attributes ) {
        push @{ $attr->has_init_arg ? \@init : \@non_init }, $attr;
    }

    my %new_params = ( ( map { $_->init_arg => $_->get_value($self) } @init ), %params );

    my $name = delete $new_params{name};

    my $clone = $class->new($name, %new_params, __hack_no_process_options => 1 );

    foreach my $attr ( @non_init ) {
        $attr->set_value($clone, $attr->get_value($self));
    }

    return $clone;
}

sub _process_options {
    my ( $class, $name, $options ) = @_;

    $class->_process_is_option( $name, $options );
    $class->_process_isa_option( $name, $options );
    $class->_process_does_option( $name, $options );
    $class->_process_coerce_option( $name, $options );
    $class->_process_trigger_option( $name, $options );
    $class->_process_auto_deref_option( $name, $options );
    $class->_process_lazy_build_option( $name, $options );
    $class->_process_lazy_option( $name, $options );
    $class->_process_required_option( $name, $options );
}

sub _process_is_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{is};

    ### -------------------------
    ## is => ro, writer => _foo    # turns into (reader => foo, writer => _foo) as before
    ## is => rw, writer => _foo    # turns into (reader => foo, writer => _foo)
    ## is => rw, accessor => _foo  # turns into (accessor => _foo)
    ## is => ro, accessor => _foo  # error, accesor is rw
    ### -------------------------

    if ( $options->{is} eq 'ro' ) {
        $class->throw_error(
            "Cannot define an accessor name on a read-only attribute, accessors are read/write",
            data => $options )
            if exists $options->{accessor};
        $options->{reader} ||= $name;
    }
    elsif ( $options->{is} eq 'rw' ) {
        if ( $options->{writer} ) {
            $options->{reader} ||= $name;
        }
        else {
            $options->{accessor} ||= $name;
        }
    }
    elsif ( $options->{is} eq 'bare' ) {
        return;
        # do nothing, but don't complain (later) about missing methods
    }
    else {
        $class->throw_error( "I do not understand this option (is => "
                . $options->{is}
                . ") on attribute ($name)", data => $options->{is} );
    }
}

sub _process_isa_option {
    my ( $class, $name, $options ) = @_;

    return unless exists $options->{isa};

    if ( exists $options->{does} ) {
        if ( try { $options->{isa}->can('does') } ) {
            ( $options->{isa}->does( $options->{does} ) )
                || $class->throw_error(
                "Cannot have an isa option and a does option if the isa does not do the does on attribute ($name)",
                data => $options );
        }
        else {
            $class->throw_error(
                "Cannot have an isa option which cannot ->does() on attribute ($name)",
                data => $options );
        }
    }

    # allow for anon-subtypes here ...
    #
    # Checking for Specio explicitly is completely revolting. At some point
    # this needs to be refactored so that Moose core defines a standard type
    # API that all types must implement. Unfortunately, the current core API
    # is _not_ the right API, so we probably need to A) come up with the new
    # API (Specio is a good start); B) refactor the core types to implement
    # that API; C) do duck type checking on type objects.
    if ( blessed( $options->{isa} )
        && $options->{isa}->isa('Moose::Meta::TypeConstraint') ) {
        $options->{type_constraint} = $options->{isa};
    }
    elsif (
        blessed( $options->{isa} )
        && Moose::Util::does_role(
            $options->{isa}, 'Specio::Constraint::Role::Interface'
        )
        ) {
        $options->{type_constraint} = $options->{isa};
    }
    else {
        $options->{type_constraint}
            = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint(
            $options->{isa},
            { package_defined_in => $options->{definition_context}->{package} }
        );
    }
}

sub _process_does_option {
    my ( $class, $name, $options ) = @_;

    return unless exists $options->{does} && ! exists $options->{isa};

    # allow for anon-subtypes here ...
    if ( blessed( $options->{does} )
        && $options->{does}->isa('Moose::Meta::TypeConstraint') ) {
        $options->{type_constraint} = $options->{does};
    }
    else {
        $options->{type_constraint}
            = Moose::Util::TypeConstraints::find_or_create_does_type_constraint(
            $options->{does},
            { package_defined_in => $options->{definition_context}->{package} }
        );
    }
}

sub _process_coerce_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{coerce};

    ( exists $options->{type_constraint} )
        || $class->throw_error(
        "You cannot have coercion without specifying a type constraint on attribute ($name)",
        data => $options );

    $class->throw_error(
        "You cannot have a weak reference to a coerced value on attribute ($name)",
        data => $options )
        if $options->{weak_ref};

    unless ( $options->{type_constraint}->has_coercion ) {
        my $type = $options->{type_constraint}->name;

        Moose::Deprecated::deprecated(
            feature => 'coerce without coercion',
            message =>
                "You cannot coerce an attribute ($name) unless its type ($type) has a coercion"
        );
    }
}

sub _process_trigger_option {
    my ( $class, $name, $options ) = @_;

    return unless exists $options->{trigger};

    ( 'CODE' eq ref $options->{trigger} )
        || $class->throw_error("Trigger must be a CODE ref on attribute ($name)", data => $options->{trigger});
}

sub _process_auto_deref_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{auto_deref};

    ( exists $options->{type_constraint} )
        || $class->throw_error(
        "You cannot auto-dereference without specifying a type constraint on attribute ($name)",
        data => $options );

    ( $options->{type_constraint}->is_a_type_of('ArrayRef')
      || $options->{type_constraint}->is_a_type_of('HashRef') )
        || $class->throw_error(
        "You cannot auto-dereference anything other than a ArrayRef or HashRef on attribute ($name)",
        data => $options );
}

sub _process_lazy_build_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{lazy_build};

    $class->throw_error(
        "You can not use lazy_build and default for the same attribute ($name)",
        data => $options )
        if exists $options->{default};

    $options->{lazy} = 1;
    $options->{builder} ||= "_build_${name}";

    if ( $name =~ /^_/ ) {
        $options->{clearer}   ||= "_clear${name}";
        $options->{predicate} ||= "_has${name}";
    }
    else {
        $options->{clearer}   ||= "clear_${name}";
        $options->{predicate} ||= "has_${name}";
    }
}

sub _process_lazy_option {
    my ( $class, $name, $options ) = @_;

    return unless $options->{lazy};

    ( exists $options->{default} || defined $options->{builder} )
        || $class->throw_error(
        "You cannot have a lazy attribute ($name) without specifying a default value for it",
        data => $options );
}

sub _process_required_option {
    my ( $class, $name, $options ) = @_;

    if (
        $options->{required}
        && !(
            ( !exists $options->{init_arg} || defined $options->{init_arg} )
            || exists $options->{default}
            || defined $options->{builder}
        )
        ) {
        $class->throw_error(
            "You cannot have a required attribute ($name) without a default, builder, or an init_arg",
            data => $options );
    }
}

sub initialize_instance_slot {
    my ($self, $meta_instance, $instance, $params) = @_;
    my $init_arg = $self->init_arg();
    # try to fetch the init arg from the %params ...

    my $val;
    my $value_is_set;
    if ( defined($init_arg) and exists $params->{$init_arg}) {
        $val = $params->{$init_arg};
        $value_is_set = 1;
    }
    else {
        # skip it if it's lazy
        return if $self->is_lazy;
        # and die if it's required and doesn't have a default value
        $self->throw_error("Attribute (" . $self->name . ") is required", object => $instance, data => $params)
            if $self->is_required && !$self->has_default && !$self->has_builder;

        # if nothing was in the %params, we can use the
        # attribute's default value (if it has one)
        if ($self->has_default) {
            $val = $self->default($instance);
            $value_is_set = 1;
        }
        elsif ($self->has_builder) {
            $val = $self->_call_builder($instance);
            $value_is_set = 1;
        }
    }

    return unless $value_is_set;

    $val = $self->_coerce_and_verify( $val, $instance );

    $self->set_initial_value($instance, $val);

    if ( ref $val && $self->is_weak_ref ) {
        $self->_weaken_value($instance);
    }
}

sub _call_builder {
    my ( $self, $instance ) = @_;

    my $builder = $self->builder();

    return $instance->$builder()
        if $instance->can( $self->builder );

    $self->throw_error(  blessed($instance)
            . " does not support builder method '"
            . $self->builder
            . "' for attribute '"
            . $self->name
            . "'",
            object => $instance,
     );
}

## Slot management

sub _make_initializer_writer_callback {
    my $self = shift;
    my ($meta_instance, $instance, $slot_name) = @_;
    my $old_callback = $self->SUPER::_make_initializer_writer_callback(@_);
    return sub {
        $old_callback->($self->_coerce_and_verify($_[0], $instance));
    };
}

sub set_value {
    my ($self, $instance, @args) = @_;
    my $value = $args[0];

    my $attr_name = quotemeta($self->name);

    if ($self->is_required and not @args) {
        $self->throw_error("Attribute ($attr_name) is required", object => $instance);
    }

    $value = $self->_coerce_and_verify( $value, $instance );

    my @old;
    if ( $self->has_trigger && $self->has_value($instance) ) {
        @old = $self->get_value($instance, 'for trigger');
    }

    $self->SUPER::set_value($instance, $value);

    if ( ref $value && $self->is_weak_ref ) {
        $self->_weaken_value($instance);
    }

    if ($self->has_trigger) {
        $self->trigger->($instance, $value, @old);
    }
}

sub _inline_set_value {
    my $self = shift;
    my ($instance, $value, $tc, $coercion, $message, $for_constructor) = @_;

    my $old     = '@old';
    my $copy    = '$val';
    $tc       ||= '$type_constraint';
    $coercion ||= '$type_coercion';
    $message  ||= '$type_message';

    my @code;
    if ($self->_writer_value_needs_copy) {
        push @code, $self->_inline_copy_value($value, $copy);
        $value = $copy;
    }

    # constructors already handle required checks
    push @code, $self->_inline_check_required
        unless $for_constructor;

    push @code, $self->_inline_tc_code($value, $tc, $coercion, $message);

    # constructors do triggers all at once at the end
    push @code, $self->_inline_get_old_value_for_trigger($instance, $old)
        unless $for_constructor;

    push @code, (
        $self->SUPER::_inline_set_value($instance, $value),
        $self->_inline_weaken_value($instance, $value),
    );

    # constructors do triggers all at once at the end
    push @code, $self->_inline_trigger($instance, $value, $old)
        unless $for_constructor;

    return @code;
}

sub _writer_value_needs_copy {
    my $self = shift;
    return $self->should_coerce;
}

sub _inline_copy_value {
    my $self = shift;
    my ($value, $copy) = @_;

    return 'my ' . $copy . ' = ' . $value . ';'
}

sub _inline_check_required {
    my $self = shift;

    return unless $self->is_required;

    my $attr_name = quotemeta($self->name);

    return (
        'if (@_ < 2) {',
            $self->_inline_throw_error(
                '"Attribute (' . $attr_name . ') is required"'
            ) . ';',
        '}',
    );
}

sub _inline_tc_code {
    my $self = shift;
    my ($value, $tc, $coercion, $message, $is_lazy) = @_;
    return (
        $self->_inline_check_coercion(
            $value, $tc, $coercion, $is_lazy,
        ),
        $self->_inline_check_constraint(
            $value, $tc, $message, $is_lazy,
        ),
    );
}

sub _inline_check_coercion {
    my $self = shift;
    my ($value, $tc, $coercion) = @_;

    return unless $self->should_coerce && $self->type_constraint->has_coercion;

    if ( $self->type_constraint->can_be_inlined ) {
        return (
            'if (! (' . $self->type_constraint->_inline_check($value) . ')) {',
                $value . ' = ' . $coercion . '->(' . $value . ');',
            '}',
        );
    }
    else {
        return (
            'if (!' . $tc . '->(' . $value . ')) {',
                $value . ' = ' . $coercion . '->(' . $value . ');',
            '}',
        );
    }
}

sub _inline_check_constraint {
    my $self = shift;
    my ($value, $tc, $message) = @_;

    return unless $self->has_type_constraint;

    my $attr_name = quotemeta($self->name);

    if ( $self->type_constraint->can_be_inlined ) {
        return (
            'if (! (' . $self->type_constraint->_inline_check($value) . ')) {',
                $self->_inline_throw_error(
                    '"Attribute (' . $attr_name . ') does not pass the type '
                  . 'constraint because: " . '
                  . 'do { local $_ = ' . $value . '; '
                      . $message . '->(' . $value . ')'
                  . '}',
                    'data => ' . $value
                ) . ';',
            '}',
        );
    }
    else {
        return (
            'if (!' . $tc . '->(' . $value . ')) {',
                $self->_inline_throw_error(
                    '"Attribute (' . $attr_name . ') does not pass the type '
                  . 'constraint because: " . '
                  . 'do { local $_ = ' . $value . '; '
                      . $message . '->(' . $value . ')'
                  . '}',
                    'data => ' . $value
                ) . ';',
            '}',
        );
    }
}

sub _inline_get_old_value_for_trigger {
    my $self = shift;
    my ($instance, $old) = @_;

    return unless $self->has_trigger;

    return (
        'my ' . $old . ' = ' . $self->_inline_instance_has($instance),
            '? ' . $self->_inline_instance_get($instance),
            ': ();',
    );
}

sub _inline_weaken_value {
    my $self = shift;
    my ($instance, $value) = @_;

    return unless $self->is_weak_ref;

    my $mi = $self->associated_class->get_meta_instance;
    return (
        $mi->inline_weaken_slot_value($instance, $self->name),
            'if ref ' . $value . ';',
    );
}

sub _inline_trigger {
    my $self = shift;
    my ($instance, $value, $old) = @_;

    return unless $self->has_trigger;

    return '$trigger->(' . $instance . ', ' . $value . ', ' . $old . ');';
}

sub _eval_environment {
    my $self = shift;

    my $env = { };

    $env->{'$trigger'} = \($self->trigger)
        if $self->has_trigger;
    $env->{'$attr_default'} = \($self->default)
        if $self->has_default;

    if ($self->has_type_constraint) {
        my $tc_obj = $self->type_constraint;

        $env->{'$type_constraint'} = \(
            $tc_obj->_compiled_type_constraint
        ) unless $tc_obj->can_be_inlined;
        # these two could probably get inlined versions too
        $env->{'$type_coercion'} = \(
            $tc_obj->coercion->_compiled_type_coercion
        ) if $tc_obj->has_coercion;
        $env->{'$type_message'} = \(
            $tc_obj->has_message ? $tc_obj->message : $tc_obj->_default_message
        );

        $env = { %$env, %{ $tc_obj->inline_environment } };
    }

    # XXX ugh, fix these
    $env->{'$attr'} = \$self
        if $self->has_initializer && $self->is_lazy;
    # pretty sure this is only going to be closed over if you use a custom
    # error class at this point, but we should still get rid of this
    # at some point
    $env->{'$meta'} = \($self->associated_class);

    return $env;
}

sub _weaken_value {
    my ( $self, $instance ) = @_;

    my $meta_instance = Class::MOP::Class->initialize( blessed($instance) )
        ->get_meta_instance;

    $meta_instance->weaken_slot_value( $instance, $self->name );
}

sub get_value {
    my ($self, $instance, $for_trigger) = @_;

    if ($self->is_lazy) {
        unless ($self->has_value($instance)) {
            my $value;
            if ($self->has_default) {
                $value = $self->default($instance);
            } elsif ( $self->has_builder ) {
                $value = $self->_call_builder($instance);
            }

            $value = $self->_coerce_and_verify( $value, $instance );

            $self->set_initial_value($instance, $value);

            if ( ref $value && $self->is_weak_ref ) {
                $self->_weaken_value($instance);
            }
        }
    }

    if ( $self->should_auto_deref && ! $for_trigger ) {

        my $type_constraint = $self->type_constraint;

        if ($type_constraint->is_a_type_of('ArrayRef')) {
            my $rv = $self->SUPER::get_value($instance);
            return unless defined $rv;
            return wantarray ? @{ $rv } : $rv;
        }
        elsif ($type_constraint->is_a_type_of('HashRef')) {
            my $rv = $self->SUPER::get_value($instance);
            return unless defined $rv;
            return wantarray ? %{ $rv } : $rv;
        }
        else {
            $self->throw_error("Can not auto de-reference the type constraint '" . $type_constraint->name . "'", object => $instance, type_constraint => $type_constraint);
        }

    }
    else {

        return $self->SUPER::get_value($instance);
    }
}

sub _inline_get_value {
    my $self = shift;
    my ($instance, $tc, $coercion, $message) = @_;

    my $slot_access = $self->_inline_instance_get($instance);
    $tc           ||= '$type_constraint';
    $coercion     ||= '$type_coercion';
    $message      ||= '$type_message';

    return (
        $self->_inline_check_lazy($instance, $tc, $coercion, $message),
        $self->_inline_return_auto_deref($slot_access),
    );
}

sub _inline_check_lazy {
    my $self = shift;
    my ($instance, $tc, $coercion, $message) = @_;

    return unless $self->is_lazy;

    my $slot_exists = $self->_inline_instance_has($instance);

    return (
        'if (!' . $slot_exists . ') {',
            $self->_inline_init_from_default($instance, '$default', $tc, $coercion, $message, 'lazy'),
        '}',
    );
}

sub _inline_init_from_default {
    my $self = shift;
    my ($instance, $default, $tc, $coercion, $message, $for_lazy) = @_;

    if (!($self->has_default || $self->has_builder)) {
        $self->throw_error(
            'You cannot have a lazy attribute '
          . '(' . $self->name . ') '
          . 'without specifying a default value for it',
            attr => $self,
        );
    }

    return (
        $self->_inline_generate_default($instance, $default),
        # intentionally not using _inline_tc_code, since that can be overridden
        # to do things like possibly only do member tc checks, which isn't
        # appropriate for checking the result of a default
        $self->has_type_constraint
            ? ($self->_inline_check_coercion($default, $tc, $coercion, $for_lazy),
               $self->_inline_check_constraint($default, $tc, $message, $for_lazy))
            : (),
        $self->_inline_init_slot($instance, $default),
        $self->_inline_weaken_value($instance, $default),
    );
}

sub _inline_generate_default {
    my $self = shift;
    my ($instance, $default) = @_;

    if ($self->has_default) {
        my $source = 'my ' . $default . ' = $attr_default';
        $source .= '->(' . $instance . ')'
            if $self->is_default_a_coderef;
        return $source . ';';
    }
    elsif ($self->has_builder) {
        my $builder = B::perlstring($self->builder);
        my $builder_str = quotemeta($self->builder);
        my $attr_name_str = quotemeta($self->name);
        return (
            'my ' . $default . ';',
            'if (my $builder = ' . $instance . '->can(' . $builder . ')) {',
                $default . ' = ' . $instance . '->$builder;',
            '}',
            'else {',
                'my $class = ref(' . $instance . ') || ' . $instance . ';',
                $self->_inline_throw_error(
                    '"$class does not support builder method '
                  . '\'' . $builder_str . '\' for attribute '
                  . '\'' . $attr_name_str . '\'"'
                ) . ';',
            '}',
        );
    }
    else {
        $self->throw_error(
            "Can't generate a default for " . $self->name
          . " since no default or builder was specified"
        );
    }
}

sub _inline_init_slot {
    my $self = shift;
    my ($inv, $value) = @_;

    if ($self->has_initializer) {
        return '$attr->set_initial_value(' . $inv . ', ' . $value . ');';
    }
    else {
        return $self->_inline_instance_set($inv, $value) . ';';
    }
}

sub _inline_return_auto_deref {
    my $self = shift;

    return 'return ' . $self->_auto_deref(@_) . ';';
}

sub _auto_deref {
    my $self = shift;
    my ($ref_value) = @_;

    return $ref_value unless $self->should_auto_deref;

    my $type_constraint = $self->type_constraint;

    my $sigil;
    if ($type_constraint->is_a_type_of('ArrayRef')) {
        $sigil = '@';
    }
    elsif ($type_constraint->is_a_type_of('HashRef')) {
        $sigil = '%';
    }
    else {
        $self->throw_error(
            'Can not auto de-reference the type constraint \''
          . $type_constraint->name
          . '\'',
            type_constraint => $type_constraint,
        );
    }

    return 'wantarray '
             . '? ' . $sigil . '{ (' . $ref_value . ') || return } '
             . ': (' . $ref_value . ')';
}

## installing accessors

sub accessor_metaclass { 'Moose::Meta::Method::Accessor' }

sub install_accessors {
    my $self = shift;
    $self->SUPER::install_accessors(@_);
    $self->install_delegation if $self->has_handles;
    return;
}

sub _check_associated_methods {
    my $self = shift;
    unless (
        @{ $self->associated_methods }
        || ($self->_is_metadata || '') eq 'bare'
    ) {
        Carp::cluck(
            'Attribute (' . $self->name . ') of class '
            . $self->associated_class->name
            . ' has no associated methods'
            . ' (did you mean to provide an "is" argument?)'
            . "\n"
        )
    }
}

sub _process_accessors {
    my $self = shift;
    my ($type, $accessor, $generate_as_inline_methods) = @_;

    $accessor = ( keys %$accessor )[0] if ( ref($accessor) || '' ) eq 'HASH';
    my $method = $self->associated_class->get_method($accessor);

    if (   $method
        && $method->isa('Class::MOP::Method::Accessor')
        && $method->associated_attribute->name ne $self->name ) {

        my $other_attr_name = $method->associated_attribute->name;
        my $name            = $self->name;

        Carp::cluck(
            "You are overwriting an accessor ($accessor) for the $other_attr_name attribute"
                . " with a new accessor method for the $name attribute" );
    }

    if (
           $method
        && !$method->is_stub
        && !$method->isa('Class::MOP::Method::Accessor')
        && (  !$self->definition_context
            || $method->package_name eq $self->definition_context->{package} )
        ) {

        Carp::cluck(
            "You are overwriting a locally defined method ($accessor) with "
                . "an accessor" );
    }

    if (  !$self->associated_class->has_method($accessor)
        && $self->associated_class->has_package_symbol( '&' . $accessor ) ) {

        Carp::cluck(
            "You are overwriting a locally defined function ($accessor) with "
                . "an accessor" );
    }

    $self->SUPER::_process_accessors(@_);
}

sub remove_accessors {
    my $self = shift;
    $self->SUPER::remove_accessors(@_);
    $self->remove_delegation if $self->has_handles;
    return;
}

sub install_delegation {
    my $self = shift;

    # NOTE:
    # Here we canonicalize the 'handles' option
    # this will sort out any details and always
    # return an hash of methods which we want
    # to delagate to, see that method for details
    my %handles = $self->_canonicalize_handles;


    # install the delegation ...
    my $associated_class = $self->associated_class;
    foreach my $handle (sort keys %handles) {
        my $method_to_call = $handles{$handle};
        my $class_name = $associated_class->name;
        my $name = "${class_name}::${handle}";

        if ( my $method = $associated_class->get_method($handle) ) {
            $self->throw_error(
                "You cannot overwrite a locally defined method ($handle) with a delegation",
                method_name => $handle
            ) unless $method->is_stub;
        }

        # NOTE:
        # handles is not allowed to delegate
        # any of these methods, as they will
        # override the ones in your class, which
        # is almost certainly not what you want.

        # FIXME warn when $handle was explicitly specified, but not if the source is a regex or something
        #cluck("Not delegating method '$handle' because it is a core method") and
        next if $class_name->isa("Moose::Object") and $handle =~ /^BUILD|DEMOLISH$/ || Moose::Object->can($handle);

        my $method = $self->_make_delegation_method($handle, $method_to_call);

        $self->associated_class->add_method($method->name, $method);
        $self->associate_method($method);
    }
}

sub remove_delegation {
    my $self = shift;
    my %handles = $self->_canonicalize_handles;
    my $associated_class = $self->associated_class;
    foreach my $handle (keys %handles) {
        next unless any { $handle eq $_ }
                    map { $_->name }
                    @{ $self->associated_methods };
        $self->associated_class->remove_method($handle);
    }
}

# private methods to help delegation ...

sub _canonicalize_handles {
    my $self    = shift;
    my $handles = $self->handles;
    if (my $handle_type = ref($handles)) {
        if ($handle_type eq 'HASH') {
            return %{$handles};
        }
        elsif ($handle_type eq 'ARRAY') {
            return map { $_ => $_ } @{$handles};
        }
        elsif ($handle_type eq 'Regexp') {
            ($self->has_type_constraint)
                || $self->throw_error("Cannot delegate methods based on a Regexp without a type constraint (isa)", data => $handles);
            return map  { ($_ => $_) }
                   grep { /$handles/ } $self->_get_delegate_method_list;
        }
        elsif ($handle_type eq 'CODE') {
            return $handles->($self, $self->_find_delegate_metaclass);
        }
        elsif (blessed($handles) && $handles->isa('Moose::Meta::TypeConstraint::DuckType')) {
            return map { $_ => $_ } @{ $handles->methods };
        }
        elsif (blessed($handles) && $handles->isa('Moose::Meta::TypeConstraint::Role')) {
            $handles = $handles->role;
        }
        else {
            $self->throw_error("Unable to canonicalize the 'handles' option with $handles", data => $handles);
        }
    }

    load_class($handles);
    my $role_meta = Class::MOP::class_of($handles);

    (blessed $role_meta && $role_meta->isa('Moose::Meta::Role'))
        || $self->throw_error("Unable to canonicalize the 'handles' option with $handles because its metaclass is not a Moose::Meta::Role", data => $handles);

    return map { $_ => $_ }
        map { $_->name }
        grep { !$_->isa('Class::MOP::Method::Meta') } (
        $role_meta->_get_local_methods,
        $role_meta->get_required_method_list,
        );
}

sub _get_delegate_method_list {
    my $self = shift;
    my $meta = $self->_find_delegate_metaclass;
    if ($meta->isa('Class::MOP::Class')) {
        return map  { $_->name }  # NOTE: !never! delegate &meta
               grep { $_->package_name ne 'Moose::Object' && !$_->isa('Class::MOP::Method::Meta') }
                    $meta->get_all_methods;
    }
    elsif ($meta->isa('Moose::Meta::Role')) {
        return $meta->get_method_list;
    }
    else {
        $self->throw_error("Unable to recognize the delegate metaclass '$meta'", data => $meta);
    }
}

sub _find_delegate_metaclass {
    my $self = shift;
    if (my $class = $self->_isa_metadata) {
        unless ( is_class_loaded($class) ) {
            $self->throw_error(
                sprintf(
                    'The %s attribute is trying to delegate to a class which has not been loaded - %s',
                    $self->name, $class
                )
            );
        }
        # we might be dealing with a non-Moose class,
        # and need to make our own metaclass. if there's
        # already a metaclass, it will be returned
        return Class::MOP::Class->initialize($class);
    }
    elsif (my $role = $self->_does_metadata) {
        unless ( is_class_loaded($class) ) {
            $self->throw_error(
                sprintf(
                    'The %s attribute is trying to delegate to a role which has not been loaded - %s',
                    $self->name, $role
                )
            );
        }

        return Class::MOP::class_of($role);
    }
    else {
        $self->throw_error("Cannot find delegate metaclass for attribute " . $self->name);
    }
}

sub delegation_metaclass { 'Moose::Meta::Method::Delegation' }

sub _make_delegation_method {
    my ( $self, $handle_name, $method_to_call ) = @_;

    my @curried_arguments;

    ($method_to_call, @curried_arguments) = @$method_to_call
        if 'ARRAY' eq ref($method_to_call);

    return $self->delegation_metaclass->new(
        name               => $handle_name,
        package_name       => $self->associated_class->name,
        attribute          => $self,
        delegate_to_method => $method_to_call,
        curried_arguments  => \@curried_arguments,
    );
}

sub _coerce_and_verify {
    my $self     = shift;
    my $val      = shift;
    my $instance = shift;

    return $val unless $self->has_type_constraint;

    $val = $self->type_constraint->coerce($val)
        if $self->should_coerce && $self->type_constraint->has_coercion;

    $self->verify_against_type_constraint($val, instance => $instance);

    return $val;
}

sub verify_against_type_constraint {
    my $self = shift;
    my $val  = shift;

    return 1 if !$self->has_type_constraint;

    my $type_constraint = $self->type_constraint;

    $type_constraint->check($val)
        || $self->throw_error("Attribute ("
                 . $self->name
                 . ") does not pass the type constraint because: "
                 . $type_constraint->get_message($val), data => $val, @_);
}

package Moose::Meta::Attribute::Custom::Moose;
BEGIN {
  $Moose::Meta::Attribute::Custom::Moose::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Attribute::Custom::Moose::VERSION = '2.1005';
}
sub register_implementation { 'Moose::Meta::Attribute' }

1;

# ABSTRACT: The Moose attribute metaclass

__END__

=pod

=head1 NAME

Moose::Meta::Attribute - The Moose attribute metaclass

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class is a subclass of L<Class::MOP::Attribute> that provides
additional Moose-specific functionality.

To really understand this class, you will need to start with the
L<Class::MOP::Attribute> documentation. This class can be understood
as a set of additional features on top of the basic feature provided
by that parent class.

=head1 INHERITANCE

C<Moose::Meta::Attribute> is a subclass of L<Class::MOP::Attribute>.

=head1 METHODS

Many of the documented below override methods in
L<Class::MOP::Attribute> and add Moose specific features.

=head2 Creation

=over 4

=item B<< Moose::Meta::Attribute->new($name, %options) >>

This method overrides the L<Class::MOP::Attribute> constructor.

Many of the options below are described in more detail in the
L<Moose::Manual::Attributes> document.

It adds the following options to the constructor:

=over 8

=item * is => 'ro', 'rw', 'bare'

This provides a shorthand for specifying the C<reader>, C<writer>, or
C<accessor> names. If the attribute is read-only ('ro') then it will
have a C<reader> method with the same attribute as the name.

If it is read-write ('rw') then it will have an C<accessor> method
with the same name. If you provide an explicit C<writer> for a
read-write attribute, then you will have a C<reader> with the same
name as the attribute, and a C<writer> with the name you provided.

Use 'bare' when you are deliberately not installing any methods
(accessor, reader, etc.) associated with this attribute; otherwise,
Moose will issue a deprecation warning when this attribute is added to a
metaclass.

=item * isa => $type

This option accepts a type. The type can be a string, which should be
a type name. If the type name is unknown, it is assumed to be a class
name.

This option can also accept a L<Moose::Meta::TypeConstraint> object.

If you I<also> provide a C<does> option, then your C<isa> option must
be a class name, and that class must do the role specified with
C<does>.

=item * does => $role

This is short-hand for saying that the attribute's type must be an
object which does the named role.

=item * coerce => $bool

This option is only valid for objects with a type constraint
(C<isa>) that defined a coercion. If this is true, then coercions will be applied whenever
this attribute is set.

You can make both this and the C<weak_ref> option true.

=item * trigger => $sub

This option accepts a subroutine reference, which will be called after
the attribute is set.

=item * required => $bool

An attribute which is required must be provided to the constructor. An
attribute which is required can also have a C<default> or C<builder>,
which will satisfy its required-ness.

A required attribute must have a C<default>, C<builder> or a
non-C<undef> C<init_arg>

=item * lazy => $bool

A lazy attribute must have a C<default> or C<builder>. When an
attribute is lazy, the default value will not be calculated until the
attribute is read.

=item * weak_ref => $bool

If this is true, the attribute's value will be stored as a weak
reference.

=item * auto_deref => $bool

If this is true, then the reader will dereference the value when it is
called. The attribute must have a type constraint which defines the
attribute as an array or hash reference.

=item * lazy_build => $bool

Setting this to true makes the attribute lazy and provides a number of
default methods.

  has 'size' => (
      is         => 'ro',
      lazy_build => 1,
  );

is equivalent to this:

  has 'size' => (
      is        => 'ro',
      lazy      => 1,
      builder   => '_build_size',
      clearer   => 'clear_size',
      predicate => 'has_size',
  );

If your attribute name starts with an underscore (C<_>), then the clearer
and predicate will as well:

  has '_size' => (
      is         => 'ro',
      lazy_build => 1,
  );

becomes:

  has '_size' => (
      is        => 'ro',
      lazy      => 1,
      builder   => '_build__size',
      clearer   => '_clear_size',
      predicate => '_has_size',
  );

Note the doubled underscore in the builder name. Internally, Moose
simply prepends the attribute name with "_build_" to come up with the
builder name.

=item * documentation

An arbitrary string that can be retrieved later by calling C<<
$attr->documentation >>.

=back

=item B<< $attr->clone(%options) >>

This creates a new attribute based on attribute being cloned. You must
supply a C<name> option to provide a new name for the attribute.

The C<%options> can only specify options handled by
L<Class::MOP::Attribute>.

=back

=head2 Value management

=over 4

=item B<< $attr->initialize_instance_slot($meta_instance, $instance, $params) >>

This method is used internally to initialize the attribute's slot in
the object C<$instance>.

This overrides the L<Class::MOP::Attribute> method to handle lazy
attributes, weak references, and type constraints.

=item B<get_value>

=item B<set_value>

  eval { $point->meta->get_attribute('x')->set_value($point, 'forty-two') };
  if($@) {
    print "Oops: $@\n";
  }

I<Attribute (x) does not pass the type constraint (Int) with 'forty-two'>

Before setting the value, a check is made on the type constraint of
the attribute, if it has one, to see if the value passes it. If the
value fails to pass, the set operation dies.

Any coercion to convert values is done before checking the type constraint.

To check a value against a type constraint before setting it, fetch the
attribute instance using L<Class::MOP::Class/find_attribute_by_name>,
fetch the type_constraint from the attribute using L<Moose::Meta::Attribute/type_constraint>
and call L<Moose::Meta::TypeConstraint/check>. See L<Moose::Cookbook::Basics::Company_Subtypes>
for an example.

=back

=head2 Attribute Accessor generation

=over 4

=item B<< $attr->install_accessors >>

This method overrides the parent to also install delegation methods.

If, after installing all methods, the attribute object has no associated
methods, it throws an error unless C<< is => 'bare' >> was passed to the
attribute constructor.  (Trying to add an attribute that has no associated
methods is almost always an error.)

=item B<< $attr->remove_accessors >>

This method overrides the parent to also remove delegation methods.

=item B<< $attr->inline_set($instance_var, $value_var) >>

This method return a code snippet suitable for inlining the relevant
operation. It expect strings containing variable names to be used in the
inlining, like C<'$self'> or C<'$_[1]'>.

=item B<< $attr->install_delegation >>

This method adds its delegation methods to the attribute's associated
class, if it has any to add.

=item B<< $attr->remove_delegation >>

This method remove its delegation methods from the attribute's
associated class.

=item B<< $attr->accessor_metaclass >>

Returns the accessor metaclass name, which defaults to
L<Moose::Meta::Method::Accessor>.

=item B<< $attr->delegation_metaclass >>

Returns the delegation metaclass name, which defaults to
L<Moose::Meta::Method::Delegation>.

=back

=head2 Additional Moose features

These methods are not found in the superclass. They support features
provided by Moose.

=over 4

=item B<< $attr->does($role) >>

This indicates whether the I<attribute itself> does the given
role. The role can be given as a full class name, or as a resolvable
trait name.

Note that this checks the attribute itself, not its type constraint,
so it is checking the attribute's metaclass and any traits applied to
the attribute.

=item B<< Moose::Meta::Class->interpolate_class_and_new($name, %options) >>

This is an alternate constructor that handles the C<metaclass> and
C<traits> options.

Effectively, this method is a factory that finds or creates the
appropriate class for the given C<metaclass> and/or C<traits>.

Once it has the appropriate class, it will call C<< $class->new($name,
%options) >> on that class.

=item B<< $attr->clone_and_inherit_options(%options) >>

This method supports the C<has '+foo'> feature. It does various bits
of processing on the supplied C<%options> before ultimately calling
the C<clone> method.

One of its main tasks is to make sure that the C<%options> provided
does not include the options returned by the
C<illegal_options_for_inheritance> method.

=item B<< $attr->illegal_options_for_inheritance >>

This returns a blacklist of options that can not be overridden in a
subclass's attribute definition.

This exists to allow a custom metaclass to change or add to the list
of options which can not be changed.

=item B<< $attr->type_constraint >>

Returns the L<Moose::Meta::TypeConstraint> object for this attribute,
if it has one.

=item B<< $attr->has_type_constraint >>

Returns true if this attribute has a type constraint.

=item B<< $attr->verify_against_type_constraint($value) >>

Given a value, this method returns true if the value is valid for the
attribute's type constraint. If the value is not valid, it throws an
error.

=item B<< $attr->handles >>

This returns the value of the C<handles> option passed to the
constructor.

=item B<< $attr->has_handles >>

Returns true if this attribute performs delegation.

=item B<< $attr->is_weak_ref >>

Returns true if this attribute stores its value as a weak reference.

=item B<< $attr->is_required >>

Returns true if this attribute is required to have a value.

=item B<< $attr->is_lazy >>

Returns true if this attribute is lazy.

=item B<< $attr->is_lazy_build >>

Returns true if the C<lazy_build> option was true when passed to the
constructor.

=item B<< $attr->should_coerce >>

Returns true if the C<coerce> option passed to the constructor was
true.

=item B<< $attr->should_auto_deref >>

Returns true if the C<auto_deref> option passed to the constructor was
true.

=item B<< $attr->trigger >>

This is the subroutine reference that was in the C<trigger> option
passed to the constructor, if any.

=item B<< $attr->has_trigger >>

Returns true if this attribute has a trigger set.

=item B<< $attr->documentation >>

Returns the value that was in the C<documentation> option passed to
the constructor, if any.

=item B<< $attr->has_documentation >>

Returns true if this attribute has any documentation.

=item B<< $attr->applied_traits >>

This returns an array reference of all the traits which were applied
to this attribute. If none were applied, this returns C<undef>.

=item B<< $attr->has_applied_traits >>

Returns true if this attribute has any traits applied.

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
