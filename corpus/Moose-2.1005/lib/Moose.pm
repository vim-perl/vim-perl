package Moose;
BEGIN {
  $Moose::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::VERSION = '2.1005';
}
use strict;
use warnings;

use 5.008;

use Scalar::Util 'blessed';
use Carp         'carp', 'confess';
use Class::Load  'is_class_loaded';

use Moose::Deprecated;
use Moose::Exporter;

use Class::MOP;

BEGIN {
    die "Class::MOP version $Moose::VERSION required--this is version $Class::MOP::VERSION"
        if $Moose::VERSION && $Class::MOP::VERSION ne $Moose::VERSION;
}

use Moose::Meta::Class;
use Moose::Meta::TypeConstraint;
use Moose::Meta::TypeCoercion;
use Moose::Meta::Attribute;
use Moose::Meta::Instance;

use Moose::Object;

use Moose::Meta::Role;
use Moose::Meta::Role::Composite;
use Moose::Meta::Role::Application;
use Moose::Meta::Role::Application::RoleSummation;
use Moose::Meta::Role::Application::ToClass;
use Moose::Meta::Role::Application::ToRole;
use Moose::Meta::Role::Application::ToInstance;

use Moose::Util::TypeConstraints;
use Moose::Util ();

use Moose::Meta::Attribute::Native;

sub throw_error {
    # FIXME This
    shift;
    goto \&confess
}

sub extends {
    my $meta = shift;

    Moose->throw_error("Must derive at least one class") unless @_;

    # this checks the metaclass to make sure
    # it is correct, sometimes it can get out
    # of sync when the classes are being built
    $meta->superclasses(@_);
}

sub with {
    Moose::Util::apply_all_roles(shift, @_);
}

sub has {
    my $meta = shift;
    my $name = shift;

    Moose->throw_error('Usage: has \'name\' => ( key => value, ... )')
        if @_ % 2 == 1;

    my %context = Moose::Util::_caller_info;
    $context{context} = 'has declaration';
    $context{type} = 'class';
    my %options = ( definition_context => \%context, @_ );
    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
    $meta->add_attribute( $_, %options ) for @$attrs;
}

sub before {
    Moose::Util::add_method_modifier(shift, 'before', \@_);
}

sub after {
    Moose::Util::add_method_modifier(shift, 'after', \@_);
}

sub around {
    Moose::Util::add_method_modifier(shift, 'around', \@_);
}

our $SUPER_PACKAGE;
our $SUPER_BODY;
our @SUPER_ARGS;

sub super {
    if (@_) {
        carp 'Arguments passed to super() are ignored';
    }

    # This check avoids a recursion loop - see
    # t/bugs/super_recursion.t
    return if defined $SUPER_PACKAGE && $SUPER_PACKAGE ne caller();
    return unless $SUPER_BODY; $SUPER_BODY->(@SUPER_ARGS);
}

sub override {
    my $meta = shift;
    my ( $name, $method ) = @_;
    $meta->add_override_method_modifier( $name => $method );
}

sub inner {
    my $pkg = caller();
    our ( %INNER_BODY, %INNER_ARGS );

    if ( my $body = $INNER_BODY{$pkg} ) {
        my @args = @{ $INNER_ARGS{$pkg} };
        local $INNER_ARGS{$pkg};
        local $INNER_BODY{$pkg};
        return $body->(@args);
    } else {
        return;
    }
}

sub augment {
    my $meta = shift;
    my ( $name, $method ) = @_;
    $meta->add_augment_method_modifier( $name => $method );
}

Moose::Exporter->setup_import_methods(
    with_meta => [
        qw( extends with has before after around override augment )
    ],
    as_is => [
        qw( super inner ),
        \&Carp::confess,
        \&Scalar::Util::blessed,
    ],
);

sub init_meta {
    shift;
    my %args = @_;

    my $class = $args{for_class}
        or Moose->throw_error("Cannot call init_meta without specifying a for_class");
    my $base_class = $args{base_class} || 'Moose::Object';
    my $metaclass  = $args{metaclass}  || 'Moose::Meta::Class';
    my $meta_name  = exists $args{meta_name} ? $args{meta_name} : 'meta';

    Moose->throw_error("The Metaclass $metaclass must be loaded. (Perhaps you forgot to 'use $metaclass'?)")
        unless is_class_loaded($metaclass);

    Moose->throw_error("The Metaclass $metaclass must be a subclass of Moose::Meta::Class.")
        unless $metaclass->isa('Moose::Meta::Class');

    # make a subtype for each Moose class
    class_type($class)
        unless find_type_constraint($class);

    my $meta;

    if ( $meta = Class::MOP::get_metaclass_by_name($class) ) {
        unless ( $meta->isa("Moose::Meta::Class") ) {
            my $error_message = "$class already has a metaclass, but it does not inherit $metaclass ($meta).";
            if ( $meta->isa('Moose::Meta::Role') ) {
                Moose->throw_error($error_message . ' You cannot make the same thing a role and a class. Remove either Moose or Moose::Role.');
            } else {
                Moose->throw_error($error_message);
            }
        }
    } else {
        # no metaclass

        # now we check whether our ancestors have metaclass, and if so borrow that
        my ( undef, @isa ) = @{ mro::get_linear_isa($class) };

        foreach my $ancestor ( @isa ) {
            my $ancestor_meta = Class::MOP::get_metaclass_by_name($ancestor) || next;

            my $ancestor_meta_class = $ancestor_meta->_real_ref_name;

            # if we have an ancestor metaclass that inherits $metaclass, we use
            # that. This is like _fix_metaclass_incompatibility, but we can do it now.

            # the case of having an ancestry is not very common, but arises in
            # e.g. Reaction
            unless ( $metaclass->isa( $ancestor_meta_class ) ) {
                if ( $ancestor_meta_class->isa($metaclass) ) {
                    $metaclass = $ancestor_meta_class;
                }
            }
        }

        $meta = $metaclass->initialize($class);
    }

    if (defined $meta_name) {
        # also check for inherited non moose 'meta' method?
        my $existing = $meta->get_method($meta_name);
        if ($existing && !$existing->isa('Class::MOP::Method::Meta')) {
            Carp::cluck "Moose is overwriting an existing method named "
                      . "$meta_name in class $class with a method "
                      . "which returns the class's metaclass. If this is "
                      . "actually what you want, you should remove the "
                      . "existing method, otherwise, you should rename or "
                      . "disable this generated method using the "
                      . "'-meta_name' option to 'use Moose'.";
        }
        $meta->_add_meta_method($meta_name);
    }

    # make sure they inherit from Moose::Object
    $meta->superclasses($base_class)
      unless $meta->superclasses();

    return $meta;
}

# This may be used in some older MooseX extensions.
sub _get_caller {
    goto &Moose::Exporter::_get_caller;
}

## make 'em all immutable

$_->make_immutable(
    inline_constructor => 1,
    constructor_name   => "_new",
    # these are Class::MOP accessors, so they need inlining
    inline_accessors => 1
    ) for grep { $_->is_mutable }
    map { $_->meta }
    qw(
    Moose::Meta::Attribute
    Moose::Meta::Class
    Moose::Meta::Instance

    Moose::Meta::TypeCoercion
    Moose::Meta::TypeCoercion::Union

    Moose::Meta::Method
    Moose::Meta::Method::Constructor
    Moose::Meta::Method::Destructor
    Moose::Meta::Method::Overridden
    Moose::Meta::Method::Augmented

    Moose::Meta::Role
    Moose::Meta::Role::Attribute
    Moose::Meta::Role::Method
    Moose::Meta::Role::Method::Required
    Moose::Meta::Role::Method::Conflicting

    Moose::Meta::Role::Composite

    Moose::Meta::Role::Application
    Moose::Meta::Role::Application::RoleSummation
    Moose::Meta::Role::Application::ToClass
    Moose::Meta::Role::Application::ToRole
    Moose::Meta::Role::Application::ToInstance
);

$_->make_immutable(
    inline_constructor => 0,
    constructor_name   => undef,
    # these are Class::MOP accessors, so they need inlining
    inline_accessors => 1
    ) for grep { $_->is_mutable }
    map { $_->meta }
    qw(
    Moose::Meta::Method::Accessor
    Moose::Meta::Method::Delegation
    Moose::Meta::Mixin::AttributeCore
);

1;

# ABSTRACT: A postmodern object system for Perl 5

__END__

=pod

=head1 NAME

Moose - A postmodern object system for Perl 5

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  package Point;
  use Moose; # automatically turns on strict and warnings

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  sub clear {
      my $self = shift;
      $self->x(0);
      $self->y(0);
  }

  package Point3D;
  use Moose;

  extends 'Point';

  has 'z' => (is => 'rw', isa => 'Int');

  after 'clear' => sub {
      my $self = shift;
      $self->z(0);
  };

=head1 DESCRIPTION

Moose is an extension of the Perl 5 object system.

The main goal of Moose is to make Perl 5 Object Oriented programming
easier, more consistent, and less tedious. With Moose you can think
more about what you want to do and less about the mechanics of OOP.

Additionally, Moose is built on top of L<Class::MOP>, which is a
metaclass system for Perl 5. This means that Moose not only makes
building normal Perl 5 objects better, but it provides the power of
metaclass programming as well.

=head2 New to Moose?

If you're new to Moose, the best place to start is the
L<Moose::Manual> docs, followed by the L<Moose::Cookbook>. The intro
will show you what Moose is, and how it makes Perl 5 OO better.

The cookbook recipes on Moose basics will get you up to speed with
many of Moose's features quickly. Once you have an idea of what Moose
can do, you can use the API documentation to get more detail on
features which interest you.

=head2 Moose Extensions

The C<MooseX::> namespace is the official place to find Moose extensions.
These extensions can be found on the CPAN.  The easiest way to find them
is to search for them (L<http://search.cpan.org/search?query=MooseX::>),
or to examine L<Task::Moose> which aims to keep an up-to-date, easily
installable list of Moose extensions.

=head1 TRANSLATIONS

Much of the Moose documentation has been translated into other languages.

=over 4

=item Japanese

Japanese docs can be found at
L<http://perldoc.perlassociation.org/pod/Moose-Doc-JA/index.html>. The
source POD files can be found in GitHub:
L<http://github.com/jpa/Moose-Doc-JA>

=back

=head1 BUILDING CLASSES WITH MOOSE

Moose makes every attempt to provide as much convenience as possible during
class construction/definition, but still stay out of your way if you want it
to. Here are a few items to note when building classes with Moose.

When you C<use Moose>, Moose will set the class's parent class to
L<Moose::Object>, I<unless> the class using Moose already has a parent
class. In addition, specifying a parent with C<extends> will change the parent
class.

Moose will also manage all attributes (including inherited ones) that are
defined with C<has>. And (assuming you call C<new>, which is inherited from
L<Moose::Object>) this includes properly initializing all instance slots,
setting defaults where appropriate, and performing any type constraint checking
or coercion.

=head1 PROVIDED METHODS

Moose provides a number of methods to all your classes, mostly through the
inheritance of L<Moose::Object>. There is however, one exception.

=over 4

=item B<meta>

This is a method which provides access to the current class's metaclass.

=back

=head1 EXPORTED FUNCTIONS

Moose will export a number of functions into the class's namespace which
may then be used to set up the class. These functions all work directly
on the current class.

=over 4

=item B<extends (@superclasses)>

This function will set the superclass(es) for the current class. If the parent
classes are not yet loaded, then C<extends> tries to load them.

This approach is recommended instead of C<use base>, because C<use base>
actually C<push>es onto the class's C<@ISA>, whereas C<extends> will
replace it. This is important to ensure that classes which do not have
superclasses still properly inherit from L<Moose::Object>.

Each superclass can be followed by a hash reference with options. Currently,
only L<-version|Class::MOP/Class Loading Options> is recognized:

    extends 'My::Parent'      => { -version => 0.01 },
            'My::OtherParent' => { -version => 0.03 };

An exception will be thrown if the version requirements are not
satisfied.

=item B<with (@roles)>

This will apply a given set of C<@roles> to the local class.

Like with C<extends>, each specified role can be followed by a hash
reference with a L<-version|Class::MOP/Class Loading Options> option:

    with 'My::Role'      => { -version => 0.32 },
         'My::Otherrole' => { -version => 0.23 };

The specified version requirements must be satisfied, otherwise an
exception will be thrown.

If your role takes options or arguments, they can be passed along in the
hash reference as well.

=item B<has $name|@$names =E<gt> %options>

This will install an attribute of a given C<$name> into the current class. If
the first parameter is an array reference, it will create an attribute for
every C<$name> in the list. The C<%options> will be passed to the constructor
for L<Moose::Meta::Attribute> (which inherits from L<Class::MOP::Attribute>),
so the full documentation for the valid options can be found there. These are
the most commonly used options:

=over 4

=item I<is =E<gt> 'rw'|'ro'>

The I<is> option accepts either I<rw> (for read/write) or I<ro> (for read
only). These will create either a read/write accessor or a read-only
accessor respectively, using the same name as the C<$name> of the attribute.

If you need more control over how your accessors are named, you can
use the L<reader|Class::MOP::Attribute/reader>,
L<writer|Class::MOP::Attribute/writer> and
L<accessor|Class::MOP::Attribute/accessor> options inherited from
L<Class::MOP::Attribute>, however if you use those, you won't need the
I<is> option.

=item I<isa =E<gt> $type_name>

The I<isa> option uses Moose's type constraint facilities to set up runtime
type checking for this attribute. Moose will perform the checks during class
construction, and within any accessors. The C<$type_name> argument must be a
string. The string may be either a class name or a type defined using
Moose's type definition features. (Refer to L<Moose::Util::TypeConstraints>
for information on how to define a new type, and how to retrieve type meta-data).

=item I<coerce =E<gt> (1|0)>

This will attempt to use coercion with the supplied type constraint to change
the value passed into any accessors or constructors. You B<must> supply a type
constraint, and that type constraint B<must> define a coercion. See
L<Moose::Cookbook::Basics::HTTP_SubtypesAndCoercion> for an example.

=item I<does =E<gt> $role_name>

This will accept the name of a role which the value stored in this attribute
is expected to have consumed.

=item I<required =E<gt> (1|0)>

This marks the attribute as being required. This means a value must be
supplied during class construction, I<or> the attribute must be lazy
and have either a default or a builder. Note that c<required> does not
say anything about the attribute's value, which can be C<undef>.

=item I<weak_ref =E<gt> (1|0)>

This will tell the class to store the value of this attribute as a weakened
reference. If an attribute is a weakened reference, it B<cannot> also be
coerced. Note that when a weak ref expires, the attribute's value becomes
undefined, and is still considered to be set for purposes of predicate,
default, etc.

=item I<lazy =E<gt> (1|0)>

This will tell the class to not create this slot until absolutely necessary.
If an attribute is marked as lazy it B<must> have a default or builder
supplied.

=item I<trigger =E<gt> $code>

The I<trigger> option is a CODE reference which will be called after
the value of the attribute is set. The CODE ref is passed the
instance itself, the updated value, and the original value if the
attribute was already set.

You B<can> have a trigger on a read-only attribute.

B<NOTE:> Triggers will only fire when you B<assign> to the attribute,
either in the constructor, or using the writer. Default and built values will
B<not> cause the trigger to be fired.

=item I<handles =E<gt> ARRAY | HASH | REGEXP | ROLE | ROLETYPE | DUCKTYPE | CODE>

The I<handles> option provides Moose classes with automated delegation features.
This is a pretty complex and powerful option. It accepts many different option
formats, each with its own benefits and drawbacks.

B<NOTE:> The class being delegated to does not need to be a Moose based class,
which is why this feature is especially useful when wrapping non-Moose classes.

All I<handles> option formats share the following traits:

You cannot override a locally defined method with a delegated method; an
exception will be thrown if you try. That is to say, if you define C<foo> in
your class, you cannot override it with a delegated C<foo>. This is almost never
something you would want to do, and if it is, you should do it by hand and not
use Moose.

You cannot override any of the methods found in Moose::Object, or the C<BUILD>
and C<DEMOLISH> methods. These will not throw an exception, but will silently
move on to the next method in the list. My reasoning for this is that you would
almost never want to do this, since it usually breaks your class. As with
overriding locally defined methods, if you do want to do this, you should do it
manually, not with Moose.

You do not I<need> to have a reader (or accessor) for the attribute in order
to delegate to it. Moose will create a means of accessing the value for you,
however this will be several times B<less> efficient then if you had given
the attribute a reader (or accessor) to use.

Below is the documentation for each option format:

=over 4

=item C<ARRAY>

This is the most common usage for I<handles>. You basically pass a list of
method names to be delegated, and Moose will install a delegation method
for each one.

=item C<HASH>

This is the second most common usage for I<handles>. Instead of a list of
method names, you pass a HASH ref where each key is the method name you
want installed locally, and its value is the name of the original method
in the class being delegated to.

This can be very useful for recursive classes like trees. Here is a
quick example (soon to be expanded into a Moose::Cookbook recipe):

  package Tree;
  use Moose;

  has 'node' => (is => 'rw', isa => 'Any');

  has 'children' => (
      is      => 'ro',
      isa     => 'ArrayRef',
      default => sub { [] }
  );

  has 'parent' => (
      is          => 'rw',
      isa         => 'Tree',
      weak_ref    => 1,
      handles     => {
          parent_node => 'node',
          siblings    => 'children',
      }
  );

In this example, the Tree package gets C<parent_node> and C<siblings> methods,
which delegate to the C<node> and C<children> methods (respectively) of the Tree
instance stored in the C<parent> slot.

You may also use an array reference to curry arguments to the original method.

  has 'thing' => (
      ...
      handles => { set_foo => [ set => 'foo' ] },
  );

  # $self->set_foo(...) calls $self->thing->set('foo', ...)

The first element of the array reference is the original method name, and the
rest is a list of curried arguments.

=item C<REGEXP>

The regexp option works very similar to the ARRAY option, except that it builds
the list of methods for you. It starts by collecting all possible methods of the
class being delegated to, then filters that list using the regexp supplied here.

B<NOTE:> An I<isa> option is required when using the regexp option format. This
is so that we can determine (at compile time) the method list from the class.
Without an I<isa> this is just not possible.

=item C<ROLE> or C<ROLETYPE>

With the role option, you specify the name of a role or a
L<role type|Moose::Meta::TypeConstraint::Role> whose "interface" then becomes
the list of methods to handle. The "interface" can be defined as; the methods
of the role and any required methods of the role. It should be noted that this
does B<not> include any method modifiers or generated attribute methods (which
is consistent with role composition).

=item C<DUCKTYPE>

With the duck type option, you pass a duck type object whose "interface" then
becomes the list of methods to handle. The "interface" can be defined as the
list of methods passed to C<duck_type> to create a duck type object. For more
information on C<duck_type> please check
L<Moose::Util::TypeConstraints>.

=item C<CODE>

This is the option to use when you really want to do something funky. You should
only use it if you really know what you are doing, as it involves manual
metaclass twiddling.

This takes a code reference, which should expect two arguments. The first is the
attribute meta-object this I<handles> is attached to. The second is the
metaclass of the class being delegated to. It expects you to return a hash (not
a HASH ref) of the methods you want mapped.

=back

=item I<traits =E<gt> [ @role_names ]>

This tells Moose to take the list of C<@role_names> and apply them to the
attribute meta-object. Custom attribute metaclass traits are useful for
extending the capabilities of the I<has> keyword: they are the simplest way to
extend the MOP, but they are still a fairly advanced topic and too much to
cover here.

See L<Metaclass and Trait Name Resolution> for details on how a trait name is
resolved to a role name.

Also see L<Moose::Cookbook::Meta::Labeled_AttributeTrait> for a metaclass
trait example.

=item I<builder> => Str

The value of this key is the name of the method that will be called to obtain
the value used to initialize the attribute. See the L<builder option docs in
Class::MOP::Attribute|Class::MOP::Attribute/builder> and/or
L<Moose::Cookbook::Basics::BinaryTree_BuilderAndLazyBuild> for more
information.

=item I<default> => SCALAR | CODE

The value of this key is the default value which will initialize the attribute.

NOTE: If the value is a simple scalar (string or number), then it can
be just passed as is.  However, if you wish to initialize it with a
HASH or ARRAY ref, then you need to wrap that inside a CODE reference.
See the L<default option docs in
Class::MOP::Attribute|Class::MOP::Attribute/default> for more
information.

=item I<clearer> => Str

Creates a method allowing you to clear the value. See the L<clearer option
docs in Class::MOP::Attribute|Class::MOP::Attribute/clearer> for more
information.

=item I<predicate> => Str

Creates a method to perform a basic test to see if a value has been set in the
attribute. See the L<predicate option docs in
Class::MOP::Attribute|Class::MOP::Attribute/predicate> for more information.

Note that the predicate will return true even for a C<weak_ref> attribute
whose value has expired.

=item I<documentation> => $string

An arbitrary string that can be retrieved later by calling C<<
$attr->documentation >>.

=back

=item B<has +$name =E<gt> %options>

This is variation on the normal attribute creator C<has> which allows you to
clone and extend an attribute from a superclass or from a role. Here is an
example of the superclass usage:

  package Foo;
  use Moose;

  has 'message' => (
      is      => 'rw',
      isa     => 'Str',
      default => 'Hello, I am a Foo'
  );

  package My::Foo;
  use Moose;

  extends 'Foo';

  has '+message' => (default => 'Hello I am My::Foo');

What is happening here is that B<My::Foo> is cloning the C<message> attribute
from its parent class B<Foo>, retaining the C<is =E<gt> 'rw'> and C<isa =E<gt>
'Str'> characteristics, but changing the value in C<default>.

Here is another example, but within the context of a role:

  package Foo::Role;
  use Moose::Role;

  has 'message' => (
      is      => 'rw',
      isa     => 'Str',
      default => 'Hello, I am a Foo'
  );

  package My::Foo;
  use Moose;

  with 'Foo::Role';

  has '+message' => (default => 'Hello I am My::Foo');

In this case, we are basically taking the attribute which the role supplied
and altering it within the bounds of this feature.

Note that you can only extend an attribute from either a superclass or a role,
you cannot extend an attribute in a role that composes over an attribute from
another role.

Aside from where the attributes come from (one from superclass, the other
from a role), this feature works exactly the same. This feature is restricted
somewhat, so as to try and force at least I<some> sanity into it. Most options work the same, but there are some exceptions:

=over 4

=item I<reader>

=item I<writer>

=item I<accessor>

=item I<clearer>

=item I<predicate>

These options can be added, but cannot override a superclass definition.

=item I<traits>

You are allowed to B<add> additional traits to the C<traits> definition.
These traits will be composed into the attribute, but preexisting traits
B<are not> overridden, or removed.

=back

=item B<before $name|@names|\@names|qr/.../ =E<gt> sub { ... }>

=item B<after $name|@names|\@names|qr/.../ =E<gt> sub { ... }>

=item B<around $name|@names|\@names|qr/.../ =E<gt> sub { ... }>

These three items are syntactic sugar for the before, after, and around method
modifier features that L<Class::MOP> provides. More information on these may be
found in L<Moose::Manual::MethodModifiers> and the
L<Class::MOP::Class documentation|Class::MOP::Class/"Method Modifiers">.

=item B<override ($name, &sub)>

An C<override> method is a way of explicitly saying "I am overriding this
method from my superclass". You can call C<super> within this method, and
it will work as expected. The same thing I<can> be accomplished with a normal
method call and the C<SUPER::> pseudo-package; it is really your choice.

=item B<super>

The keyword C<super> is a no-op when called outside of an C<override> method. In
the context of an C<override> method, it will call the next most appropriate
superclass method with the same arguments as the original method.

=item B<augment ($name, &sub)>

An C<augment> method, is a way of explicitly saying "I am augmenting this
method from my superclass". Once again, the details of how C<inner> and
C<augment> work is best described in the
L<Moose::Cookbook::Basics::Document_AugmentAndInner>.

=item B<inner>

The keyword C<inner>, much like C<super>, is a no-op outside of the context of
an C<augment> method. You can think of C<inner> as being the inverse of
C<super>; the details of how C<inner> and C<augment> work is best described in
the L<Moose::Cookbook::Basics::Document_AugmentAndInner>.

=item B<blessed>

This is the C<Scalar::Util::blessed> function. It is highly recommended that
this is used instead of C<ref> anywhere you need to test for an object's class
name.

=item B<confess>

This is the C<Carp::confess> function, and exported here for historical
reasons.

=back

=head1 METACLASS

When you use Moose, you can specify traits which will be applied to your
metaclass:

    use Moose -traits => 'My::Trait';

This is very similar to the attribute traits feature. When you do
this, your class's C<meta> object will have the specified traits
applied to it. See L<Metaclass and Trait Name Resolution> for more
details.

=head2 Metaclass and Trait Name Resolution

By default, when given a trait name, Moose simply tries to load a
class of the same name. If such a class does not exist, it then looks
for a class matching
B<Moose::Meta::$type::Custom::Trait::$trait_name>. The C<$type>
variable here will be one of B<Attribute> or B<Class>, depending on
what the trait is being applied to.

If a class with this long name exists, Moose checks to see if it has
the method C<register_implementation>. This method is expected to
return the I<real> class name of the trait. If there is no
C<register_implementation> method, it will fall back to using
B<Moose::Meta::$type::Custom::Trait::$trait> as the trait name.

The lookup method for metaclasses is the same, except that it looks
for a class matching B<Moose::Meta::$type::Custom::$metaclass_name>.

If all this is confusing, take a look at
L<Moose::Cookbook::Meta::Labeled_AttributeTrait>, which demonstrates how to
create an attribute trait.

=head1 UNIMPORTING FUNCTIONS

=head2 B<unimport>

Moose offers a way to remove the keywords it exports, through the C<unimport>
method. You simply have to say C<no Moose> at the bottom of your code for this
to work. Here is an example:

    package Person;
    use Moose;

    has 'first_name' => (is => 'rw', isa => 'Str');
    has 'last_name'  => (is => 'rw', isa => 'Str');

    sub full_name {
        my $self = shift;
        $self->first_name . ' ' . $self->last_name
    }

    no Moose; # keywords are removed from the Person package

=head1 EXTENDING AND EMBEDDING MOOSE

To learn more about extending Moose, we recommend checking out the
"Extending" recipes in the L<Moose::Cookbook>, starting with
L<Moose::Cookbook::Extending::ExtensionOverview>, which provides an overview of
all the different ways you might extend Moose. L<Moose::Exporter> and
L<Moose::Util::MetaRole> are the modules which provide the majority of the
extension functionality, so reading their documentation should also be helpful.

=head2 The MooseX:: namespace

Generally if you're writing an extension I<for> Moose itself you'll want
to put your extension in the C<MooseX::> namespace. This namespace is
specifically for extensions that make Moose better or different in some
fundamental way. It is traditionally B<not> for a package that just happens
to use Moose. This namespace follows from the examples of the C<LWPx::>
and C<DBIx::> namespaces that perform the same function for C<LWP> and C<DBI>
respectively.

=head1 METACLASS COMPATIBILITY AND MOOSE

Metaclass compatibility is a thorny subject. You should start by
reading the "About Metaclass compatibility" section in the
C<Class::MOP> docs.

Moose will attempt to resolve a few cases of metaclass incompatibility
when you set the superclasses for a class, in addition to the cases that
C<Class::MOP> handles.

Moose tries to determine if the metaclasses only "differ by roles". This
means that the parent and child's metaclass share a common ancestor in
their respective hierarchies, and that the subclasses under the common
ancestor are only different because of role applications. This case is
actually fairly common when you mix and match various C<MooseX::*>
modules, many of which apply roles to the metaclass.

If the parent and child do differ by roles, Moose replaces the
metaclass in the child with a newly created metaclass. This metaclass
is a subclass of the parent's metaclass which does all of the roles that
the child's metaclass did before being replaced. Effectively, this
means the new metaclass does all of the roles done by both the
parent's and child's original metaclasses.

Ultimately, this is all transparent to you except in the case of an
unresolvable conflict.

=head1 CAVEATS

=over 4

=item *

It should be noted that C<super> and C<inner> B<cannot> be used in the same
method. However, they may be combined within the same class hierarchy; see
F<t/basics/override_augment_inner_super.t> for an example.

The reason for this is that C<super> is only valid within a method
with the C<override> modifier, and C<inner> will never be valid within an
C<override> method. In fact, C<augment> will skip over any C<override> methods
when searching for its appropriate C<inner>.

This might seem like a restriction, but I am of the opinion that keeping these
two features separate (yet interoperable) actually makes them easy to use, since
their behavior is then easier to predict. Time will tell whether I am right or
not (UPDATE: so far so good).

=back

=head1 GETTING HELP

We offer both a mailing list and a very active IRC channel.

The mailing list is L<mailto:moose@perl.org>. You must be subscribed to send
a message. To subscribe, send an empty message to
L<mailto:moose-subscribe@perl.org>

You can also visit us at C<#moose> on L<irc://irc.perl.org/#moose>
This channel is quite active, and questions at all levels (on Moose-related
topics ;) are welcome.

=head1 WHAT DOES MOOSE STAND FOR?

Moose doesn't stand for one thing in particular, however, if you want, here
are a few of our favorites. Feel free to contribute more!

=over 4

=item * Make Other Object Systems Envious

=item * Makes Object Orientation So Easy

=item * Makes Object Orientation Spiffy- Er (sorry ingy)

=item * Most Other Object Systems Emasculate

=item * Moose Often Ovulate Sorta Early

=item * Moose Offers Often Super Extensions

=item * Meta Object Obligates Salivary Excitation

=item * Meta Object Orientation Syntax Extensions

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item I blame Sam Vilain for introducing me to the insanity that is meta-models.

=item I blame Audrey Tang for then encouraging my meta-model habit in #perl6.

=item Without Yuval "nothingmuch" Kogman this module would not be possible,
and it certainly wouldn't have this name ;P

=item The basis of the TypeContraints module was Rob Kinyon's idea
originally, I just ran with it.

=item Thanks to mst & chansen and the whole #moose posse for all the
early ideas/feature-requests/encouragement/bug-finding.

=item Thanks to David "Theory" Wheeler for meta-discussions and spelling fixes.

=back

=head1 SEE ALSO

=over 4

=item L<http://www.iinteractive.com/moose>

This is the official web home of Moose. It contains links to our public git
repository, as well as links to a number of talks and articles on Moose and
Moose related technologies.

=item the L<Moose manual|Moose::Manual>

This is an introduction to Moose which covers most of the basics.

=item Modern Perl, by chromatic

This is an introduction to modern Perl programming, which includes a section on
Moose. It is available in print and as a free download from
L<http://onyxneon.com/books/modern_perl/>.

=item The Moose is flying, a tutorial by Randal Schwartz

Part 1 - L<http://www.stonehenge.com/merlyn/LinuxMag/col94.html>

Part 2 - L<http://www.stonehenge.com/merlyn/LinuxMag/col95.html>

=item Several Moose extension modules in the C<MooseX::> namespace.

See L<http://search.cpan.org/search?query=MooseX::> for extensions.

=back

=head2 Books

=over 4

=item The Art of the MetaObject Protocol

I mention this in the L<Class::MOP> docs too, as this book was critical in
the development of both modules and is highly recommended.

=back

=head2 Papers

=over 4

=item L<http://www.cs.utah.edu/plt/publications/oopsla04-gff.pdf>

This paper (suggested by lbr on #moose) was what lead to the implementation
of the C<super>/C<override> and C<inner>/C<augment> features. If you really
want to understand them, I suggest you read this.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception.

Please report any bugs to C<bug-moose@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.

You can also discuss feature requests or possible bugs on the Moose mailing
list (moose@perl.org) or on IRC at L<irc://irc.perl.org/#moose>.

=head1 FEATURE REQUESTS

We are very strict about what features we add to the Moose core, especially
the user-visible features. Instead we have made sure that the underlying
meta-system of Moose is as extensible as possible so that you can add your
own features easily.

That said, occasionally there is a feature needed in the meta-system
to support your planned extension, in which case you should either
email the mailing list (moose@perl.org) or join us on IRC at
L<irc://irc.perl.org/#moose> to discuss. The
L<Moose::Manual::Contributing> has more detail about how and when you
can contribute.

=head1 CABAL

There are only a few people with the rights to release a new version
of Moose. The Moose Cabal are the people to go to with questions regarding
the wider purview of Moose. They help maintain not just the code
but the community as well.

Stevan (stevan) Little E<lt>stevan@iinteractive.comE<gt>

Jesse (doy) Luehrs E<lt>doy at tozt dot netE<gt>

Yuval (nothingmuch) Kogman

Shawn (sartak) Moore E<lt>sartak@bestpractical.comE<gt>

Hans Dieter (confound) Pearcey E<lt>hdp@pobox.comE<gt>

Chris (perigrin) Prather

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

Dave (autarch) Rolsky E<lt>autarch@urth.orgE<gt>

Karen (ether) Etheridge E<lt>ether@cpan.orgE<gt>

=head1 CONTRIBUTORS

Moose is a community project, and as such, involves the work of many, many
members of the community beyond just the members in the cabal. In particular:

Dave (autarch) Rolsky wrote most of the documentation in L<Moose::Manual>.

John (jgoulah) Goulah wrote L<Moose::Cookbook::Snack::Keywords>.

Jess (castaway) Robinson wrote L<Moose::Cookbook::Snack::Types>.

Aran (bluefeet) Clary Deltac wrote
L<Moose::Cookbook::Basics::Genome_OverloadingSubtypesAndCoercion>.

Anders (Debolaz) Nor Berle contributed L<Test::Moose> and L<Moose::Util>.

Also, the code in L<Moose::Meta::Attribute::Native> is based on code from the
L<MooseX::AttributeHelpers> distribution, which had contributions from:

Chris (perigrin) Prather

Cory (gphat) Watson

Evan Carroll

Florian (rafl) Ragwitz

Jason May

Jay Hannah

Jesse (doy) Luehrs

Paul (frodwith) Driver

Robert (rlb3) Boone

Robert Buels

Robert (phaylon) Sedlacek

Shawn (Sartak) Moore

Stevan Little

Tom (dec) Lanyon

Yuval Kogman

Finally, these people also contributed various tests, bug fixes,
documentation, and features to the Moose codebase:

Aankhen

Adam (Alias) Kennedy

Christian (chansen) Hansen

Cory (gphat) Watson

Dylan Hardison (doc fixes)

Eric (ewilhelm) Wilhelm

Evan Carroll

Guillermo (groditi) Roditi

Jason May

Jay Hannah

Jonathan (jrockway) Rockway

Matt (mst) Trout

Nathan (kolibrie) Gray

Paul (frodwith) Driver

Piotr (dexter) Roszatycki

Robert Buels

Robert (phaylon) Sedlacek

Robert (rlb3) Boone

Sam (mugwump) Vilain

Scott (konobi) McWhirter

Shlomi (rindolf) Fish

Tom (dec) Lanyon

Wallace (wreis) Reis

... and many other #moose folks

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
