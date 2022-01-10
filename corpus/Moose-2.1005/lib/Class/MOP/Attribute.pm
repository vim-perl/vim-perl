
package Class::MOP::Attribute;
BEGIN {
  $Class::MOP::Attribute::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Attribute::VERSION = '2.1005';
}

use strict;
use warnings;

use Class::MOP::Method::Accessor;

use Carp         'confess';
use Scalar::Util 'blessed', 'weaken';
use Try::Tiny;

use base 'Class::MOP::Object', 'Class::MOP::Mixin::AttributeCore';

# NOTE: (meta-circularity)
# This method will be replaced in the
# boostrap section of Class::MOP, by
# a new version which uses the
# &Class::MOP::Class::construct_instance
# method to build an attribute meta-object
# which itself is described with attribute
# meta-objects.
#     - Ain't meta-circularity grand? :)
sub new {
    my ( $class, @args ) = @_;

    unshift @args, "name" if @args % 2 == 1;
    my %options = @args;

    my $name = $options{name};

    (defined $name)
        || confess "You must provide a name for the attribute";

    $options{init_arg} = $name
        if not exists $options{init_arg};
    if(exists $options{builder}){
        confess("builder must be a defined scalar value which is a method name")
            if ref $options{builder} || !(defined $options{builder});
        confess("Setting both default and builder is not allowed.")
            if exists $options{default};
    } else {
        ($class->is_default_a_coderef(\%options))
            || confess("References are not allowed as default values, you must ".
                       "wrap the default of '$name' in a CODE reference (ex: sub { [] } and not [])")
                if exists $options{default} && ref $options{default};
    }
    if( $options{required} and not( defined($options{builder}) || defined($options{init_arg}) || exists $options{default} ) ) {
        confess("A required attribute must have either 'init_arg', 'builder', or 'default'");
    }

    $class->_new(\%options);
}

sub _new {
    my $class = shift;

    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $options = @_ == 1 ? $_[0] : {@_};

    bless {
        'name'               => $options->{name},
        'accessor'           => $options->{accessor},
        'reader'             => $options->{reader},
        'writer'             => $options->{writer},
        'predicate'          => $options->{predicate},
        'clearer'            => $options->{clearer},
        'builder'            => $options->{builder},
        'init_arg'           => $options->{init_arg},
        exists $options->{default}
            ? ('default'     => $options->{default})
            : (),
        'initializer'        => $options->{initializer},
        'definition_context' => $options->{definition_context},
        # keep a weakened link to the
        # class we are associated with
        'associated_class' => undef,
        # and a list of the methods
        # associated with this attr
        'associated_methods' => [],
        # this let's us keep track of
        # our order inside the associated
        # class
        'insertion_order'    => undef,
    }, $class;
}

# NOTE:
# this is a primitive (and kludgy) clone operation
# for now, it will be replaced in the Class::MOP
# bootstrap with a proper one, however we know
# that this one will work fine for now.
sub clone {
    my $self    = shift;
    my %options = @_;
    (blessed($self))
        || confess "Can only clone an instance";
    return bless { %{$self}, %options } => ref($self);
}

sub initialize_instance_slot {
    my ($self, $meta_instance, $instance, $params) = @_;
    my $init_arg = $self->{'init_arg'};

    # try to fetch the init arg from the %params ...

    # if nothing was in the %params, we can use the
    # attribute's default value (if it has one)
    if(defined $init_arg and exists $params->{$init_arg}){
        $self->_set_initial_slot_value(
            $meta_instance,
            $instance,
            $params->{$init_arg},
        );
    }
    elsif (exists $self->{'default'}) {
        $self->_set_initial_slot_value(
            $meta_instance,
            $instance,
            $self->default($instance),
        );
    }
    elsif (defined( my $builder = $self->{'builder'})) {
        if ($builder = $instance->can($builder)) {
            $self->_set_initial_slot_value(
                $meta_instance,
                $instance,
                $instance->$builder,
            );
        }
        else {
            confess(ref($instance)." does not support builder method '". $self->{'builder'} ."' for attribute '" . $self->name . "'");
        }
    }
}

sub _set_initial_slot_value {
    my ($self, $meta_instance, $instance, $value) = @_;

    my $slot_name = $self->name;

    return $meta_instance->set_slot_value($instance, $slot_name, $value)
        unless $self->has_initializer;

    my $callback = $self->_make_initializer_writer_callback(
        $meta_instance, $instance, $slot_name
    );

    my $initializer = $self->initializer;

    # most things will just want to set a value, so make it first arg
    $instance->$initializer($value, $callback, $self);
}

sub _make_initializer_writer_callback {
    my $self = shift;
    my ($meta_instance, $instance, $slot_name) = @_;

    return sub {
        $meta_instance->set_slot_value($instance, $slot_name, $_[0]);
    };
}

sub get_read_method  {
    my $self   = shift;
    my $reader = $self->reader || $self->accessor;
    # normal case ...
    return $reader unless ref $reader;
    # the HASH ref case
    my ($name) = %$reader;
    return $name;
}

sub get_write_method {
    my $self   = shift;
    my $writer = $self->writer || $self->accessor;
    # normal case ...
    return $writer unless ref $writer;
    # the HASH ref case
    my ($name) = %$writer;
    return $name;
}

sub get_read_method_ref {
    my $self = shift;
    if ((my $reader = $self->get_read_method) && $self->associated_class) {
        return $self->associated_class->get_method($reader);
    }
    else {
        my $code = sub { $self->get_value(@_) };
        if (my $class = $self->associated_class) {
            return $class->method_metaclass->wrap(
                $code,
                package_name => $class->name,
                name         => '__ANON__'
            );
        }
        else {
            return $code;
        }
    }
}

sub get_write_method_ref {
    my $self = shift;
    if ((my $writer = $self->get_write_method) && $self->associated_class) {
        return $self->associated_class->get_method($writer);
    }
    else {
        my $code = sub { $self->set_value(@_) };
        if (my $class = $self->associated_class) {
            return $class->method_metaclass->wrap(
                $code,
                package_name => $class->name,
                name         => '__ANON__'
            );
        }
        else {
            return $code;
        }
    }
}

# slots

sub slots { (shift)->name }

# class association

sub attach_to_class {
    my ($self, $class) = @_;
    (blessed($class) && $class->isa('Class::MOP::Class'))
        || confess "You must pass a Class::MOP::Class instance (or a subclass)";
    weaken($self->{'associated_class'} = $class);
}

sub detach_from_class {
    my $self = shift;
    $self->{'associated_class'} = undef;
}

# method association

sub associate_method {
    my ($self, $method) = @_;
    push @{$self->{'associated_methods'}} => $method;
}

## Slot management

sub set_initial_value {
    my ($self, $instance, $value) = @_;
    $self->_set_initial_slot_value(
        Class::MOP::Class->initialize(ref($instance))->get_meta_instance,
        $instance,
        $value
    );
}

sub set_value { shift->set_raw_value(@_) }

sub set_raw_value {
    my $self = shift;
    my ($instance, $value) = @_;

    my $mi = Class::MOP::Class->initialize(ref($instance))->get_meta_instance;
    return $mi->set_slot_value($instance, $self->name, $value);
}

sub _inline_set_value {
    my $self = shift;
    return $self->_inline_instance_set(@_) . ';';
}

sub _inline_instance_set {
    my $self = shift;
    my ($instance, $value) = @_;

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_set_slot_value($instance, $self->name, $value);
}

sub get_value { shift->get_raw_value(@_) }

sub get_raw_value {
    my $self = shift;
    my ($instance) = @_;

    my $mi = Class::MOP::Class->initialize(ref($instance))->get_meta_instance;
    return $mi->get_slot_value($instance, $self->name);
}

sub _inline_get_value {
    my $self = shift;
    return $self->_inline_instance_get(@_) . ';';
}

sub _inline_instance_get {
    my $self = shift;
    my ($instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_get_slot_value($instance, $self->name);
}

sub has_value {
    my $self = shift;
    my ($instance) = @_;

    my $mi = Class::MOP::Class->initialize(ref($instance))->get_meta_instance;
    return $mi->is_slot_initialized($instance, $self->name);
}

sub _inline_has_value {
    my $self = shift;
    return $self->_inline_instance_has(@_) . ';';
}

sub _inline_instance_has {
    my $self = shift;
    my ($instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_is_slot_initialized($instance, $self->name);
}

sub clear_value {
    my $self = shift;
    my ($instance) = @_;

    my $mi = Class::MOP::Class->initialize(ref($instance))->get_meta_instance;
    return $mi->deinitialize_slot($instance, $self->name);
}

sub _inline_clear_value {
    my $self = shift;
    return $self->_inline_instance_clear(@_) . ';';
}

sub _inline_instance_clear {
    my $self = shift;
    my ($instance) = @_;

    my $mi = $self->associated_class->get_meta_instance;
    return $mi->inline_deinitialize_slot($instance, $self->name);
}

## load em up ...

sub accessor_metaclass { 'Class::MOP::Method::Accessor' }

sub _process_accessors {
    my ($self, $type, $accessor, $generate_as_inline_methods) = @_;

    my $method_ctx = { %{ $self->definition_context || {} } };

    if (ref($accessor)) {
        (ref($accessor) eq 'HASH')
            || confess "bad accessor/reader/writer/predicate/clearer format, must be a HASH ref";
        my ($name, $method) = %{$accessor};

        $method_ctx->{description} = $self->_accessor_description($name, $type);

        $method = $self->accessor_metaclass->wrap(
            $method,
            attribute    => $self,
            package_name => $self->associated_class->name,
            name         => $name,
            associated_metaclass => $self->associated_class,
            definition_context => $method_ctx,
        );
        $self->associate_method($method);
        return ($name, $method);
    }
    else {
        my $inline_me = ($generate_as_inline_methods && $self->associated_class->instance_metaclass->is_inlinable);
        my $method;
        try {
            $method_ctx->{description} = $self->_accessor_description($accessor, $type);

            $method = $self->accessor_metaclass->new(
                attribute     => $self,
                is_inline     => $inline_me,
                accessor_type => $type,
                package_name  => $self->associated_class->name,
                name          => $accessor,
                associated_metaclass => $self->associated_class,
                definition_context => $method_ctx,
            );
        }
        catch {
            confess "Could not create the '$type' method for " . $self->name . " because : $_";
        };
        $self->associate_method($method);
        return ($accessor, $method);
    }
}

sub _accessor_description {
    my $self = shift;
    my ($name, $type) = @_;

    my $desc = "$type " . $self->associated_class->name . "::$name";
    if ( $name ne $self->name ) {
        $desc .= " of attribute " . $self->name;
    }

    return $desc;
}

sub install_accessors {
    my $self   = shift;
    my $inline = shift;
    my $class  = $self->associated_class;

    $class->add_method(
        $self->_process_accessors('accessor' => $self->accessor(), $inline)
    ) if $self->has_accessor();

    $class->add_method(
        $self->_process_accessors('reader' => $self->reader(), $inline)
    ) if $self->has_reader();

    $class->add_method(
        $self->_process_accessors('writer' => $self->writer(), $inline)
    ) if $self->has_writer();

    $class->add_method(
        $self->_process_accessors('predicate' => $self->predicate(), $inline)
    ) if $self->has_predicate();

    $class->add_method(
        $self->_process_accessors('clearer' => $self->clearer(), $inline)
    ) if $self->has_clearer();

    return;
}

{
    my $_remove_accessor = sub {
        my ($accessor, $class) = @_;
        if (ref($accessor) && ref($accessor) eq 'HASH') {
            ($accessor) = keys %{$accessor};
        }
        my $method = $class->get_method($accessor);
        $class->remove_method($accessor)
            if (ref($method) && $method->isa('Class::MOP::Method::Accessor'));
    };

    sub remove_accessors {
        my $self = shift;
        # TODO:
        # we really need to make sure to remove from the
        # associates methods here as well. But this is
        # such a slimly used method, I am not worried
        # about it right now.
        $_remove_accessor->($self->accessor(),  $self->associated_class()) if $self->has_accessor();
        $_remove_accessor->($self->reader(),    $self->associated_class()) if $self->has_reader();
        $_remove_accessor->($self->writer(),    $self->associated_class()) if $self->has_writer();
        $_remove_accessor->($self->predicate(), $self->associated_class()) if $self->has_predicate();
        $_remove_accessor->($self->clearer(),   $self->associated_class()) if $self->has_clearer();
        return;
    }

}

1;

# ABSTRACT: Attribute Meta Object

__END__

=pod

=head1 NAME

Class::MOP::Attribute - Attribute Meta Object

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  Class::MOP::Attribute->new(
      foo => (
          accessor  => 'foo',           # dual purpose get/set accessor
          predicate => 'has_foo',       # predicate check for defined-ness
          init_arg  => '-foo',          # class->new will look for a -foo key
          default   => 'BAR IS BAZ!'    # if no -foo key is provided, use this
      )
  );

  Class::MOP::Attribute->new(
      bar => (
          reader    => 'bar',           # getter
          writer    => 'set_bar',       # setter
          predicate => 'has_bar',       # predicate check for defined-ness
          init_arg  => ':bar',          # class->new will look for a :bar key
                                        # no default value means it is undef
      )
  );

=head1 DESCRIPTION

The Attribute Protocol is almost entirely an invention of
C<Class::MOP>. Perl 5 does not have a consistent notion of
attributes. There are so many ways in which this is done, and very few
(if any) are easily discoverable by this module.

With that said, this module attempts to inject some order into this
chaos, by introducing a consistent API which can be used to create
object attributes.

=head1 METHODS

=head2 Creation

=over 4

=item B<< Class::MOP::Attribute->new($name, ?%options) >>

An attribute must (at the very least), have a C<$name>. All other
C<%options> are added as key-value pairs.

=over 8

=item * init_arg

This is a string value representing the expected key in an
initialization hash. For instance, if we have an C<init_arg> value of
C<-foo>, then the following code will Just Work.

  MyClass->meta->new_object( -foo => 'Hello There' );

If an init_arg is not assigned, it will automatically use the
attribute's name. If C<init_arg> is explicitly set to C<undef>, the
attribute cannot be specified during initialization.

=item * builder

This provides the name of a method that will be called to initialize
the attribute. This method will be called on the object after it is
constructed. It is expected to return a valid value for the attribute.

=item * default

This can be used to provide an explicit default for initializing the
attribute. If the default you provide is a subroutine reference, then
this reference will be called I<as a method> on the object.

If the value is a simple scalar (string or number), then it can be
just passed as is. However, if you wish to initialize it with a HASH
or ARRAY ref, then you need to wrap that inside a subroutine
reference:

  Class::MOP::Attribute->new(
      'foo' => (
          default => sub { [] },
      )
  );

  # or ...

  Class::MOP::Attribute->new(
      'foo' => (
          default => sub { {} },
      )
  );

If you wish to initialize an attribute with a subroutine reference
itself, then you need to wrap that in a subroutine as well:

  Class::MOP::Attribute->new(
      'foo' => (
          default => sub {
              sub { print "Hello World" }
          },
      )
  );

And lastly, if the value of your attribute is dependent upon some
other aspect of the instance structure, then you can take advantage of
the fact that when the C<default> value is called as a method:

  Class::MOP::Attribute->new(
      'object_identity' => (
          default => sub { Scalar::Util::refaddr( $_[0] ) },
      )
  );

Note that there is no guarantee that attributes are initialized in any
particular order, so you cannot rely on the value of some other
attribute when generating the default.

=item * initializer

This option can be either a method name or a subroutine
reference. This method will be called when setting the attribute's
value in the constructor. Unlike C<default> and C<builder>, the
initializer is only called when a value is provided to the
constructor. The initializer allows you to munge this value during
object construction.

The initializer is called as a method with three arguments. The first
is the value that was passed to the constructor. The second is a
subroutine reference that can be called to actually set the
attribute's value, and the last is the associated
C<Class::MOP::Attribute> object.

This contrived example shows an initializer that sets the attribute to
twice the given value.

  Class::MOP::Attribute->new(
      'doubled' => (
          initializer => sub {
              my ( $self, $value, $set, $attr ) = @_;
              $set->( $value * 2 );
          },
      )
  );

Since an initializer can be a method name, you can easily make
attribute initialization use the writer:

  Class::MOP::Attribute->new(
      'some_attr' => (
          writer      => 'some_attr',
          initializer => 'some_attr',
      )
  );

Your writer (actually, a wrapper around the writer, using
L<method modifications|Moose::Manual::MethodModifiers>) will need to examine
C<@_> and determine under which
context it is being called:

  around 'some_attr' => sub {
      my $orig = shift;
      my $self = shift;
      # $value is not defined if being called as a reader
      # $setter and $attr are only defined if being called as an initializer
      my ($value, $setter, $attr) = @_;

      # the reader behaves normally
      return $self->$orig if not @_;

      # mutate $value as desired
      # $value = <something($value);

      # if called as an initializer, set the value and we're done
      return $setter->($row) if $setter;

      # otherwise, call the real writer with the new value
      $self->$orig($row);
  };

=back

The C<accessor>, C<reader>, C<writer>, C<predicate> and C<clearer>
options all accept the same parameters. You can provide the name of
the method, in which case an appropriate default method will be
generated for you. Or instead you can also provide hash reference
containing exactly one key (the method name) and one value. The value
should be a subroutine reference, which will be installed as the
method itself.

=over 8

=item * accessor

An C<accessor> is a standard Perl-style read/write accessor. It will
return the value of the attribute, and if a value is passed as an
argument, it will assign that value to the attribute.

Note that C<undef> is a legitimate value, so this will work:

  $object->set_something(undef);

=item * reader

This is a basic read-only accessor. It returns the value of the
attribute.

=item * writer

This is a basic write accessor, it accepts a single argument, and
assigns that value to the attribute.

Note that C<undef> is a legitimate value, so this will work:

  $object->set_something(undef);

=item * predicate

The predicate method returns a boolean indicating whether or not the
attribute has been explicitly set.

Note that the predicate returns true even if the attribute was set to
a false value (C<0> or C<undef>).

=item * clearer

This method will uninitialize the attribute. After an attribute is
cleared, its C<predicate> will return false.

=item * definition_context

Mostly, this exists as a hook for the benefit of Moose.

This option should be a hash reference containing several keys which
will be used when inlining the attribute's accessors. The keys should
include C<line>, the line number where the attribute was created, and
either C<file> or C<description>.

This information will ultimately be used when eval'ing inlined
accessor code so that error messages report a useful line and file
name.

=back

=item B<< $attr->clone(%options) >>

This clones the attribute. Any options you provide will override the
settings of the original attribute. You can change the name of the new
attribute by passing a C<name> key in C<%options>.

=back

=head2 Informational

These are all basic read-only accessors for the values passed into
the constructor.

=over 4

=item B<< $attr->name >>

Returns the attribute's name.

=item B<< $attr->accessor >>

=item B<< $attr->reader >>

=item B<< $attr->writer >>

=item B<< $attr->predicate >>

=item B<< $attr->clearer >>

The C<accessor>, C<reader>, C<writer>, C<predicate>, and C<clearer>
methods all return exactly what was passed to the constructor, so it
can be either a string containing a method name, or a hash reference.

=item B<< $attr->initializer >>

Returns the initializer as passed to the constructor, so this may be
either a method name or a subroutine reference.

=item B<< $attr->init_arg >>

=item B<< $attr->is_default_a_coderef >>

=item B<< $attr->builder >>

=item B<< $attr->default($instance) >>

The C<$instance> argument is optional. If you don't pass it, the
return value for this method is exactly what was passed to the
constructor, either a simple scalar or a subroutine reference.

If you I<do> pass an C<$instance> and the default is a subroutine
reference, then the reference is called as a method on the
C<$instance> and the generated value is returned.

=item B<< $attr->slots >>

Return a list of slots required by the attribute. This is usually just
one, the name of the attribute.

A slot is the name of the hash key used to store the attribute in an
object instance.

=item B<< $attr->get_read_method >>

=item B<< $attr->get_write_method >>

Returns the name of a method suitable for reading or writing the value
of the attribute in the associated class.

If an attribute is read- or write-only, then these methods can return
C<undef> as appropriate.

=item B<< $attr->has_read_method >>

=item B<< $attr->has_write_method >>

This returns a boolean indicating whether the attribute has a I<named>
read or write method.

=item B<< $attr->get_read_method_ref >>

=item B<< $attr->get_write_method_ref >>

Returns the subroutine reference of a method suitable for reading or
writing the attribute's value in the associated class. These methods
always return a subroutine reference, regardless of whether or not the
attribute is read- or write-only.

=item B<< $attr->insertion_order >>

If this attribute has been inserted into a class, this returns a zero
based index regarding the order of insertion.

=back

=head2 Informational predicates

These are all basic predicate methods for the values passed into C<new>.

=over 4

=item B<< $attr->has_accessor >>

=item B<< $attr->has_reader >>

=item B<< $attr->has_writer >>

=item B<< $attr->has_predicate >>

=item B<< $attr->has_clearer >>

=item B<< $attr->has_initializer >>

=item B<< $attr->has_init_arg >>

This will be I<false> if the C<init_arg> was set to C<undef>.

=item B<< $attr->has_default >>

This will be I<false> if the C<default> was set to C<undef>, since
C<undef> is the default C<default> anyway.

=item B<< $attr->has_builder >>

=item B<< $attr->has_insertion_order >>

This will be I<false> if this attribute has not be inserted into a class

=back

=head2 Value management

These methods are basically "back doors" to the instance, and can be
used to bypass the regular accessors, but still stay within the MOP.

These methods are not for general use, and should only be used if you
really know what you are doing.

=over 4

=item B<< $attr->initialize_instance_slot($meta_instance, $instance, $params) >>

This method is used internally to initialize the attribute's slot in
the object C<$instance>.

The C<$params> is a hash reference of the values passed to the object
constructor.

It's unlikely that you'll need to call this method yourself.

=item B<< $attr->set_value($instance, $value) >>

Sets the value without going through the accessor. Note that this
works even with read-only attributes.

=item B<< $attr->set_raw_value($instance, $value) >>

Sets the value with no side effects such as a trigger.

This doesn't actually apply to Class::MOP attributes, only to subclasses.

=item B<< $attr->set_initial_value($instance, $value) >>

Sets the value without going through the accessor. This method is only
called when the instance is first being initialized.

=item B<< $attr->get_value($instance) >>

Returns the value without going through the accessor. Note that this
works even with write-only accessors.

=item B<< $attr->get_raw_value($instance) >>

Returns the value without any side effects such as lazy attributes.

Doesn't actually apply to Class::MOP attributes, only to subclasses.

=item B<< $attr->has_value($instance) >>

Return a boolean indicating whether the attribute has been set in
C<$instance>. This how the default C<predicate> method works.

=item B<< $attr->clear_value($instance) >>

This will clear the attribute's value in C<$instance>. This is what
the default C<clearer> calls.

Note that this works even if the attribute does not have any
associated read, write or clear methods.

=back

=head2 Class association

These methods allow you to manage the attributes association with
the class that contains it. These methods should not be used
lightly, nor are they very magical, they are mostly used internally
and by metaclass instances.

=over 4

=item B<< $attr->associated_class >>

This returns the C<Class::MOP::Class> with which this attribute is
associated, if any.

=item B<< $attr->attach_to_class($metaclass) >>

This method stores a weakened reference to the C<$metaclass> object
internally.

This method does not remove the attribute from its old class,
nor does it create any accessors in the new class.

It is probably best to use the L<Class::MOP::Class> C<add_attribute>
method instead.

=item B<< $attr->detach_from_class >>

This method removes the associate metaclass object from the attribute
it has one.

This method does not remove the attribute itself from the class, or
remove its accessors.

It is probably best to use the L<Class::MOP::Class>
C<remove_attribute> method instead.

=back

=head2 Attribute Accessor generation

=over 4

=item B<< $attr->accessor_metaclass >>

Accessor methods are generated using an accessor metaclass. By
default, this is L<Class::MOP::Method::Accessor>. This method returns
the name of the accessor metaclass that this attribute uses.

=item B<< $attr->associate_method($method) >>

This associates a L<Class::MOP::Method> object with the
attribute. Typically, this is called internally when an attribute
generates its accessors.

=item B<< $attr->associated_methods >>

This returns the list of methods which have been associated with the
attribute.

=item B<< $attr->install_accessors >>

This method generates and installs code the attributes various
accessors. It is typically called from the L<Class::MOP::Class>
C<add_attribute> method.

=item B<< $attr->remove_accessors >>

This method removes all of the accessors associated with the
attribute.

This does not currently remove methods from the list returned by
C<associated_methods>.

=item B<< $attr->inline_get >>

=item B<< $attr->inline_set >>

=item B<< $attr->inline_has >>

=item B<< $attr->inline_clear >>

These methods return a code snippet suitable for inlining the relevant
operation. They expect strings containing variable names to be used in the
inlining, like C<'$self'> or C<'$_[1]'>.

=back

=head2 Introspection

=over 4

=item B<< Class::MOP::Attribute->meta >>

This will return a L<Class::MOP::Class> instance for this class.

It should also be noted that L<Class::MOP> will actually bootstrap
this module by installing a number of attribute meta-objects into its
metaclass.

=back

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
