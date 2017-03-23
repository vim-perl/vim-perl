package Moose::Meta::Method::Accessor::Native;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::VERSION = '2.1005';
}

use strict;
use warnings;

use Carp qw( confess );
use Scalar::Util qw( blessed weaken );

use Moose::Role;

around new => sub {
    my $orig = shift;
    my $class   = shift;
    my %options = @_;

    $options{curried_arguments} = []
        unless exists $options{curried_arguments};

    confess 'You must supply a curried_arguments which is an ARRAY reference'
        unless $options{curried_arguments}
            && ref($options{curried_arguments}) eq 'ARRAY';

    my $attr_context = $options{attribute}->definition_context;
    my $desc = 'native delegation method ';
    $desc   .= $options{attribute}->associated_class->name;
    $desc   .= '::' . $options{name};
    $desc   .= " ($options{delegate_to_method})";
    $desc   .= " of attribute " . $options{attribute}->name;
    $options{definition_context} = {
        %{ $attr_context || {} },
        description => $desc,
    };

    $options{accessor_type} = 'native';

    return $class->$orig(%options);
};

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    return bless $options, $class;
}

sub root_types { (shift)->{'root_types'} }

sub _initialize_body {
    my $self = shift;

    $self->{'body'} = $self->_compile_code( [$self->_generate_method] );

    return;
}

sub _inline_curried_arguments {
    my $self = shift;

    return unless @{ $self->curried_arguments };

    return 'unshift @_, @curried;';
}

sub _inline_check_argument_count {
    my $self = shift;

    my @code;

    if (my $min = $self->_minimum_arguments) {
        push @code, (
            'if (@_ < ' . $min . ') {',
                $self->_inline_throw_error(
                    sprintf(
                        '"Cannot call %s without at least %s argument%s"',
                        $self->delegate_to_method,
                        $min,
                        ($min == 1 ? '' : 's'),
                    )
                ) . ';',
            '}',
        );
    }

    if (defined(my $max = $self->_maximum_arguments)) {
        push @code, (
            'if (@_ > ' . $max . ') {',
                $self->_inline_throw_error(
                    sprintf(
                        '"Cannot call %s with %s argument%s"',
                        $self->delegate_to_method,
                        $max ? "more than $max" : 'any',
                        ($max == 1 ? '' : 's'),
                    )
                ) . ';',
            '}',
        );
    }

    return @code;
}

sub _inline_return_value {
    my $self = shift;
    my ($slot_access, $for_writer) = @_;

    return 'return ' . $self->_return_value($slot_access, $for_writer) . ';';
}

sub _minimum_arguments { 0 }
sub _maximum_arguments { undef }

override _get_value => sub {
    my $self = shift;
    my ($instance) = @_;

    return $self->_slot_access_can_be_inlined
        ? super()
        : $instance . '->$reader';
};

override _inline_store_value => sub {
    my $self = shift;
    my ($instance, $value) = @_;

    return $self->_slot_access_can_be_inlined
        ? super()
        : $instance . '->$writer(' . $value . ');';
};

override _eval_environment => sub {
    my $self = shift;

    my $env = super();

    $env->{'@curried'} = $self->curried_arguments;

    return $env if $self->_slot_access_can_be_inlined;

    my $reader = $self->associated_attribute->get_read_method_ref;
    $reader = $reader->body if blessed $reader;

    $env->{'$reader'} = \$reader;

    my $writer = $self->associated_attribute->get_write_method_ref;
    $writer = $writer->body if blessed $writer;

    $env->{'$writer'} = \$writer;

    return $env;
};

sub _slot_access_can_be_inlined {
    my $self = shift;

    return $self->is_inline && $self->_instance_is_inlinable;
}

no Moose::Role;

1;
