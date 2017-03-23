package Class::MOP::Mixin::HasAttributes;
BEGIN {
  $Class::MOP::Mixin::HasAttributes::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Mixin::HasAttributes::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use base 'Class::MOP::Mixin';

sub add_attribute {
    my $self = shift;

    my $attribute
        = blessed( $_[0] ) ? $_[0] : $self->attribute_metaclass->new(@_);

    ( $attribute->isa('Class::MOP::Mixin::AttributeCore') )
        || confess
        "Your attribute must be an instance of Class::MOP::Mixin::AttributeCore (or a subclass)";

    $self->_attach_attribute($attribute);

    my $attr_name = $attribute->name;

    $self->remove_attribute($attr_name)
        if $self->has_attribute($attr_name);

    my $order = ( scalar keys %{ $self->_attribute_map } );
    $attribute->_set_insertion_order($order);

    $self->_attribute_map->{$attr_name} = $attribute;

    # This method is called to allow for installing accessors. Ideally, we'd
    # use method overriding, but then the subclass would be responsible for
    # making the attribute, which would end up with lots of code
    # duplication. Even more ideally, we'd use augment/inner, but this is
    # Class::MOP!
    $self->_post_add_attribute($attribute)
        if $self->can('_post_add_attribute');

    return $attribute;
}

sub has_attribute {
    my ( $self, $attribute_name ) = @_;

    ( defined $attribute_name )
        || confess "You must define an attribute name";

    exists $self->_attribute_map->{$attribute_name};
}

sub get_attribute {
    my ( $self, $attribute_name ) = @_;

    ( defined $attribute_name )
        || confess "You must define an attribute name";

    return $self->_attribute_map->{$attribute_name};
}

sub remove_attribute {
    my ( $self, $attribute_name ) = @_;

    ( defined $attribute_name )
        || confess "You must define an attribute name";

    my $removed_attribute = $self->_attribute_map->{$attribute_name};
    return unless defined $removed_attribute;

    delete $self->_attribute_map->{$attribute_name};

    return $removed_attribute;
}

sub get_attribute_list {
    my $self = shift;
    keys %{ $self->_attribute_map };
}

sub _restore_metaattributes_from {
    my $self = shift;
    my ($old_meta) = @_;

    for my $attr (sort { $a->insertion_order <=> $b->insertion_order }
                       map { $old_meta->get_attribute($_) }
                           $old_meta->get_attribute_list) {
        $attr->_make_compatible_with($self->attribute_metaclass);
        $self->add_attribute($attr);
    }
}

1;

# ABSTRACT: Methods for metaclasses which have attributes

__END__

=pod

=head1 NAME

Class::MOP::Mixin::HasAttributes - Methods for metaclasses which have attributes

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This class implements methods for metaclasses which have attributes
(L<Class::MOP::Class> and L<Moose::Meta::Role>). See L<Class::MOP::Class> for
API details.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
