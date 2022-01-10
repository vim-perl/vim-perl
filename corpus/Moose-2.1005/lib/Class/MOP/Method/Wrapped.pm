
package Class::MOP::Method::Wrapped;
BEGIN {
  $Class::MOP::Method::Wrapped::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Method::Wrapped::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use base 'Class::MOP::Method';

# NOTE:
# this ugly beast is the result of trying
# to micro optimize this as much as possible
# while not completely loosing maintainability.
# At this point it's "fast enough", after all
# you can't get something for nothing :)
my $_build_wrapped_method = sub {
    my $modifier_table = shift;
    my ($before, $after, $around) = (
        $modifier_table->{before},
        $modifier_table->{after},
        $modifier_table->{around},
    );
    if (@$before && @$after) {
        $modifier_table->{cache} = sub {
            for my $c (@$before) { $c->(@_) };
            my @rval;
            ((defined wantarray) ?
                ((wantarray) ?
                    (@rval = $around->{cache}->(@_))
                    :
                    ($rval[0] = $around->{cache}->(@_)))
                :
                $around->{cache}->(@_));
            for my $c (@$after) { $c->(@_) };
            return unless defined wantarray;
            return wantarray ? @rval : $rval[0];
        }
    }
    elsif (@$before && !@$after) {
        $modifier_table->{cache} = sub {
            for my $c (@$before) { $c->(@_) };
            return $around->{cache}->(@_);
        }
    }
    elsif (@$after && !@$before) {
        $modifier_table->{cache} = sub {
            my @rval;
            ((defined wantarray) ?
                ((wantarray) ?
                    (@rval = $around->{cache}->(@_))
                    :
                    ($rval[0] = $around->{cache}->(@_)))
                :
                $around->{cache}->(@_));
            for my $c (@$after) { $c->(@_) };
            return unless defined wantarray;
            return wantarray ? @rval : $rval[0];
        }
    }
    else {
        $modifier_table->{cache} = $around->{cache};
    }
};

sub wrap {
    my ( $class, $code, %params ) = @_;

    (blessed($code) && $code->isa('Class::MOP::Method'))
        || confess "Can only wrap blessed CODE";

    my $modifier_table = {
        cache  => undef,
        orig   => $code->body,
        before => [],
        after  => [],
        around => {
            cache   => $code->body,
            methods => [],
        },
    };
    $_build_wrapped_method->($modifier_table);
    return $class->SUPER::wrap(
        sub { $modifier_table->{cache}->(@_) },
        # get these from the original
        # unless explicitly overridden
        package_name   => $params{package_name} || $code->package_name,
        name           => $params{name}         || $code->name,
        original_method => $code,

        modifier_table => $modifier_table,
    );
}

sub _new {
    my $class = shift;
    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};

    return bless {
        # inherited from Class::MOP::Method
        'body'                 => $params->{body},
        'associated_metaclass' => $params->{associated_metaclass},
        'package_name'         => $params->{package_name},
        'name'                 => $params->{name},
        'original_method'      => $params->{original_method},

        # defined in this class
        'modifier_table'       => $params->{modifier_table}
    } => $class;
}

sub get_original_method {
    my $code = shift;
    $code->original_method;
}

sub add_before_modifier {
    my $code     = shift;
    my $modifier = shift;
    unshift @{$code->{'modifier_table'}->{before}} => $modifier;
    $_build_wrapped_method->($code->{'modifier_table'});
}

sub before_modifiers {
    my $code = shift;
    return @{$code->{'modifier_table'}->{before}};
}

sub add_after_modifier {
    my $code     = shift;
    my $modifier = shift;
    push @{$code->{'modifier_table'}->{after}} => $modifier;
    $_build_wrapped_method->($code->{'modifier_table'});
}

sub after_modifiers {
    my $code = shift;
    return @{$code->{'modifier_table'}->{after}};
}

{
    # NOTE:
    # this is another possible candidate for
    # optimization as well. There is an overhead
    # associated with the currying that, if
    # eliminated might make around modifiers
    # more manageable.
    my $compile_around_method = sub {{
        my $f1 = pop;
        return $f1 unless @_;
        my $f2 = pop;
        push @_, sub { $f2->( $f1, @_ ) };
        redo;
    }};

    sub add_around_modifier {
        my $code     = shift;
        my $modifier = shift;
        unshift @{$code->{'modifier_table'}->{around}->{methods}} => $modifier;
        $code->{'modifier_table'}->{around}->{cache} = $compile_around_method->(
            @{$code->{'modifier_table'}->{around}->{methods}},
            $code->{'modifier_table'}->{orig}
        );
        $_build_wrapped_method->($code->{'modifier_table'});
    }
}

sub around_modifiers {
    my $code = shift;
    return @{$code->{'modifier_table'}->{around}->{methods}};
}

sub _make_compatible_with {
    my $self = shift;
    my ($other) = @_;

    # XXX: this is pretty gross. the issue here is that CMOP::Method::Wrapped
    # objects are subclasses of CMOP::Method, but when we get to moose, they'll
    # need to be compatible with Moose::Meta::Method, which isn't possible. the
    # right solution here is to make ::Wrapped into a role that gets applied to
    # whatever the method_metaclass happens to be and get rid of
    # wrapped_method_metaclass entirely, but that's not going to happen until
    # we ditch cmop and get roles into the bootstrapping, so. i'm not
    # maintaining the previous behavior of turning them into instances of the
    # new method_metaclass because that's equally broken, and at least this way
    # any issues will at least be detectable and potentially fixable. -doy
    return $self unless $other->_is_compatible_with($self->_real_ref_name);

    return $self->SUPER::_make_compatible_with(@_);
}

1;

# ABSTRACT: Method Meta Object for methods with before/after/around modifiers

__END__

=pod

=head1 NAME

Class::MOP::Method::Wrapped - Method Meta Object for methods with before/after/around modifiers

=head1 VERSION

version 2.1005

=head1 DESCRIPTION

This is a L<Class::MOP::Method> subclass which implements before,
after, and around method modifiers.

=head1 METHODS

=head2 Construction

=over 4

=item B<< Class::MOP::Method::Wrapped->wrap($metamethod, %options) >>

This is the constructor. It accepts a L<Class::MOP::Method> object and
a hash of options.

The options are:

=over 8

=item * name

The method name (without a package name). This will be taken from the
provided L<Class::MOP::Method> object if it is not provided.

=item * package_name

The package name for the method. This will be taken from the provided
L<Class::MOP::Method> object if it is not provided.

=item * associated_metaclass

An optional L<Class::MOP::Class> object. This is the metaclass for the
method's class.

=back

=item B<< $metamethod->get_original_method >>

This returns the L<Class::MOP::Method> object that was passed to the
constructor.

=item B<< $metamethod->add_before_modifier($code) >>

=item B<< $metamethod->add_after_modifier($code) >>

=item B<< $metamethod->add_around_modifier($code) >>

These methods all take a subroutine reference and apply it as a
modifier to the original method.

=item B<< $metamethod->before_modifiers >>

=item B<< $metamethod->after_modifiers >>

=item B<< $metamethod->around_modifiers >>

These methods all return a list of subroutine references which are
acting as the specified type of modifier.

=back

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
