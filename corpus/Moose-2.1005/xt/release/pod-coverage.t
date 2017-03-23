#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Pod::Coverage' => '1.04',    # skip all if not installed
};

# This is a stripped down version of all_pod_coverage_ok which lets us
# vary the trustme parameter per module.
my @modules
    = grep { !/Accessor::Native.*$/ && !/::Conflicts$/ } all_modules();
plan tests => scalar @modules;

my %trustme = (
    'Class::MOP' => [
        'DEBUG_NO_META',
        'HAVE_ISAREV',
        'IS_RUNNING_ON_5_10',
        'subname',
        'in_global_destruction',
        'check_package_cache_flag',
        'load_first_existing_class',
        'is_class_loaded',
        'load_class',
    ],
    'Class::MOP::Attribute' => ['process_accessors'],
    'Class::MOP::Class'     => [
        # deprecated
        'alias_method',
        'compute_all_applicable_attributes',
        'compute_all_applicable_methods',

        # unfinished feature
        'add_dependent_meta_instance',
        'add_meta_instance_dependencies',
        'invalidate_meta_instance',
        'invalidate_meta_instances',
        'remove_dependent_meta_instance',
        'remove_meta_instance_dependencies',
        'update_meta_instance_dependencies',

        # effectively internal
        'check_metaclass_compatibility',
        'clone_instance',
        'construct_class_instance',
        'construct_instance',
        'create_meta_instance',
        'reset_package_cache_flag',
        'update_package_cache_flag',
        'reinitialize',

        # doc'd with rebless_instance
        'rebless_instance_away',

        # deprecated
        'get_attribute_map',
    ],
    'Class::MOP::Class::Immutable::Trait'             => ['.+'],
    'Class::MOP::Class::Immutable::Class::MOP::Class' => ['.+'],
    'Class::MOP::Deprecated'                          => ['.+'],
    'Class::MOP::Instance'                            => [
        qw( BUILDARGS
            bless_instance_structure
            is_dependent_on_superclasses ),
    ],
    'Class::MOP::Instance' => [
        qw( BUILDARGS
            bless_instance_structure
            is_dependent_on_superclasses ),
    ],
    'Class::MOP::Method::Accessor' => [
        qw( generate_accessor_method
            generate_accessor_method_inline
            generate_clearer_method
            generate_clearer_method_inline
            generate_predicate_method
            generate_predicate_method_inline
            generate_reader_method
            generate_reader_method_inline
            generate_writer_method
            generate_writer_method_inline
            initialize_body
            )
    ],
    'Class::MOP::Method::Constructor' => [
        qw( attributes
            generate_constructor_method
            generate_constructor_method_inline
            initialize_body
            meta_instance
            options
            )
    ],
    'Class::MOP::Method::Generated' => [
        qw( new
            definition_context
            is_inline
            initialize_body
            )
    ],
    'Class::MOP::MiniTrait'            => ['.+'],
    'Class::MOP::Mixin::AttributeCore' => ['.+'],
    'Class::MOP::Mixin::HasAttributes' => ['.+'],
    'Class::MOP::Mixin::HasMethods'    => ['.+'],
    'Class::MOP::Package'    => [ 'get_method_map', 'wrap_method_body' ],
    'Moose' => ['init_meta', 'throw_error'],
    'Moose::Error::Confess'  => ['new'],
    'Moose::Error::Util' => ['.+'],
    'Moose::Meta::Attribute' => [
        qw( interpolate_class
            throw_error
            attach_to_class
            )
    ],
    'Moose::Meta::Attribute::Native::MethodProvider::Array'   => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::Bool'    => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::Code'    => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::Counter' => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::Hash'    => ['.+'],
    'Moose::Meta::Attribute::Native::MethodProvider::String'  => ['.+'],
    'Moose::Meta::Class'                                      => [
        qw( check_metaclass_compatibility
            construct_instance
            create_error
            raise_error
            reinitialize
            superclasses
            )
    ],
    'Moose::Meta::Class::Immutable::Trait' => ['.+'],
    'Moose::Meta::Method'                  => ['throw_error'],
    'Moose::Meta::Method::Accessor'        => [
        qw( generate_accessor_method
            generate_accessor_method_inline
            generate_clearer_method
            generate_predicate_method
            generate_reader_method
            generate_reader_method_inline
            generate_writer_method
            generate_writer_method_inline
            new
            )
    ],
    'Moose::Meta::Method::Constructor' => [
        qw( attributes
            initialize_body
            meta_instance
            new
            options
            )
    ],
    'Moose::Meta::Method::Destructor' => [ 'initialize_body', 'options' ],
    'Moose::Meta::Method::Meta'       => ['wrap'],
    'Moose::Meta::Role'               => [
        qw( alias_method
            get_method_modifier_list
            reinitialize
            reset_package_cache_flag
            update_package_cache_flag
            wrap_method_body
            )
    ],
    'Moose::Meta::Mixin::AttributeCore' => ['.+'],
    'Moose::Meta::Role::Composite' =>
        [ 'get_method', 'get_method_list', 'has_method', 'add_method' ],
    'Moose::Object' => ['BUILDALL', 'DEMOLISHALL'],
    'Moose::Role' => [
        qw( after
            around
            augment
            before
            extends
            has
            inner
            override
            super
            with
            init_meta )
    ],
    'Moose::Meta::TypeCoercion'        => ['compile_type_coercion'],
    'Moose::Meta::TypeCoercion::Union' => ['compile_type_coercion'],
    'Moose::Meta::TypeConstraint' => [qw( compile_type_constraint inlined )],
    'Moose::Meta::TypeConstraint::Class' =>
        [qw( equals is_a_type_of is_a_subtype_of )],
    'Moose::Meta::TypeConstraint::Enum' => [qw( constraint equals )],
    'Moose::Meta::TypeConstraint::DuckType' =>
        [qw( constraint equals get_message )],
    'Moose::Meta::TypeConstraint::Parameterizable' => ['.+'],
    'Moose::Meta::TypeConstraint::Parameterized'   => ['.+'],
    'Moose::Meta::TypeConstraint::Role' => [qw( equals is_a_type_of )],
    'Moose::Meta::TypeConstraint::Union' => [
        qw( compile_type_constraint
            coercion
            has_coercion
            can_be_inlined
            inline_environment )
    ],
    'Moose::Util'                  => ['add_method_modifier'],
    'Moose::Util::MetaRole'        => ['apply_metaclass_roles'],
    'Moose::Util::TypeConstraints' => ['find_or_create_type_constraint'],
    'Moose::Util::TypeConstraints::Builtins' => ['.+'],
);

for my $module ( sort @modules ) {

    my $trustme = [];
    if ( $trustme{$module} ) {
        my $methods = join '|', @{ $trustme{$module} };
        $trustme = [qr/^(?:$methods)$/];
    }

    pod_coverage_ok(
        $module, { trustme => $trustme },
        "Pod coverage for $module"
    );
}
