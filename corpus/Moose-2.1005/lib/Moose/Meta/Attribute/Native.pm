package Moose::Meta::Attribute::Native;
BEGIN {
  $Moose::Meta::Attribute::Native::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Attribute::Native::VERSION = '2.1005';
}

use Class::Load qw(load_class);

my @trait_names = qw(Bool Counter Number String Array Hash Code);

for my $trait_name (@trait_names) {
    my $trait_class = "Moose::Meta::Attribute::Native::Trait::$trait_name";
    my $meta = Class::MOP::Class->initialize(
        "Moose::Meta::Attribute::Custom::Trait::$trait_name"
    );
    if ($meta->find_method_by_name('register_implementation')) {
        my $class = $meta->name->register_implementation;
        Moose->throw_error(
            "An implementation for $trait_name already exists " .
            "(found '$class' when trying to register '$trait_class')"
        );
    }
    $meta->add_method(register_implementation => sub {
        # resolve_metatrait_alias will load classes anyway, but throws away
        # their error message; we WANT to die if there's a problem
        load_class($trait_class);
        return $trait_class;
    });
}

1;

# ABSTRACT: Delegate to native Perl types

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native - Delegate to native Perl types

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  package MyClass;
  use Moose;

  has 'mapping' => (
      traits  => ['Hash'],
      is      => 'rw',
      isa     => 'HashRef[Str]',
      default => sub { {} },
      handles => {
          exists_in_mapping => 'exists',
          ids_in_mapping    => 'keys',
          get_mapping       => 'get',
          set_mapping       => 'set',
          set_quantity      => [ set => 'quantity' ],
      },
  );

  my $obj = MyClass->new;
  $obj->set_quantity(10);      # quantity => 10
  $obj->set_mapping('foo', 4); # foo => 4
  $obj->set_mapping('bar', 5); # bar => 5
  $obj->set_mapping('baz', 6); # baz => 6

  # prints 5
  print $obj->get_mapping('bar') if $obj->exists_in_mapping('bar');

  # prints 'quantity, foo, bar, baz'
  print join ', ', $obj->ids_in_mapping;

=head1 DESCRIPTION

Native delegations allow you to delegate to native Perl data
structures as if they were objects. For example, in the L</SYNOPSIS> you can
see a hash reference being treated as if it has methods named C<exists()>,
C<keys()>, C<get()>, and C<set()>.

The delegation methods (mostly) map to Perl builtins and operators. The return
values of these delegations should be the same as the corresponding Perl
operation. Any deviations will be explicitly documented.

=head1 API

Native delegations are enabled by passing certain options to C<has> when
creating an attribute.

=head2 traits

To enable this feature, pass the appropriate name in the C<traits> array
reference for the attribute. For example, to enable this feature for hash
reference, we include C<'Hash'> in the list of traits.

=head2 isa

You will need to make sure that the attribute has an appropriate type. For
example, to use this with a Hash you must specify that your attribute is some
sort of C<HashRef>.

=head2 handles

This is just like any other delegation, but only a hash reference is allowed
when defining native delegations. The keys are the methods to be created in
the class which contains the attribute. The values are the methods provided by
the associated trait. Currying works the same way as it does with any other
delegation.

See the docs for each native trait for details on what methods are available.

=head2 is

Some traits provide a default C<is> for historical reasons. This behavior is
deprecated, and you are strongly encouraged to provide a value. If you don't
plan to read and write the attribute value directly, not passing the C<is>
option will prevent standard accessor generation.

=head2 default or builder

Some traits provide a default C<default> for historical reasons. This behavior
is deprecated, and you are strongly encouraged to provide a default value or
make the attribute required.

=head1 TRAITS FOR NATIVE DELEGATIONS

Below are some simple examples of each native trait. More features are
available than what is shown here; this is just a quick synopsis.

=over

=item Array (L<Moose::Meta::Attribute::Native::Trait::Array>)

    has 'queue' => (
        traits  => ['Array'],
        is      => 'ro',
        isa     => 'ArrayRef[Str]',
        default => sub { [] },
        handles => {
            add_item  => 'push',
            next_item => 'shift',
            # ...
        }
    );

=item Bool (L<Moose::Meta::Attribute::Native::Trait::Bool>)

    has 'is_lit' => (
        traits  => ['Bool'],
        is      => 'ro',
        isa     => 'Bool',
        default => 0,
        handles => {
            illuminate  => 'set',
            darken      => 'unset',
            flip_switch => 'toggle',
            is_dark     => 'not',
            # ...
        }
    );

=item Code (L<Moose::Meta::Attribute::Native::Trait::Code>)

    has 'callback' => (
        traits  => ['Code'],
        is      => 'ro',
        isa     => 'CodeRef',
        default => sub {
            sub {'called'}
        },
        handles => {
            call => 'execute',
            # ...
        }
    );

=item Counter (L<Moose::Meta::Attribute::Native::Trait::Counter>)

    has 'counter' => (
        traits  => ['Counter'],
        is      => 'ro',
        isa     => 'Num',
        default => 0,
        handles => {
            inc_counter   => 'inc',
            dec_counter   => 'dec',
            reset_counter => 'reset',
            # ...
        }
    );

=item Hash (L<Moose::Meta::Attribute::Native::Trait::Hash>)

    has 'options' => (
        traits  => ['Hash'],
        is      => 'ro',
        isa     => 'HashRef[Str]',
        default => sub { {} },
        handles => {
            set_option => 'set',
            get_option => 'get',
            has_option => 'exists',
            # ...
        }
    );

=item Number (L<Moose::Meta::Attribute::Native::Trait::Number>)

    has 'integer' => (
        traits  => ['Number'],
        is      => 'ro',
        isa     => 'Int',
        default => 5,
        handles => {
            set => 'set',
            add => 'add',
            sub => 'sub',
            mul => 'mul',
            div => 'div',
            mod => 'mod',
            abs => 'abs',
            # ...
        }
    );

=item String (L<Moose::Meta::Attribute::Native::Trait::String>)

    has 'text' => (
        traits  => ['String'],
        is      => 'ro',
        isa     => 'Str',
        default => q{},
        handles => {
            add_text     => 'append',
            replace_text => 'replace',
            # ...
        }
    );

=back

=head1 COMPATIBILITY WITH MooseX::AttributeHelpers

This feature used to be a separated CPAN distribution called
L<MooseX::AttributeHelpers>.

When the feature was incorporated into the Moose core, some of the API details
were changed. The underlying capabilities are the same, but some details of
the API were changed.

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
