package Moose::Meta::Method::Accessor::Native::String::substr;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::String::substr::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::String::substr::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Util ();

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Reader',
     'Moose::Meta::Method::Accessor::Native::Writer';

sub _generate_method {
    my $self = shift;

    my $inv         = '$self';
    my $slot_access = $self->_get_value($inv);

    return (
        'sub {',
            'my ' . $inv . ' = shift;',
            $self->_inline_curried_arguments,
            'if (@_ == 1 || @_ == 2) {',
                $self->_inline_reader_core($inv, $slot_access),
            '}',
            'elsif (@_ == 3) {',
                $self->_inline_writer_core($inv, $slot_access),
            '}',
            'else {',
                $self->_inline_check_argument_count,
            '}',
        '}',
    );
}

sub _minimum_arguments { 1 }
sub _maximum_arguments { 3 }

sub _inline_process_arguments {
    my $self = shift;
    my ($inv, $slot_access) = @_;

    return (
        'my $offset = shift;',
        'my $length = @_ ? shift : length ' . $slot_access . ';',
        'my $replacement = shift;',
    );
}

sub _inline_check_arguments {
    my $self = shift;
    my ($for_writer) = @_;

    my @code = (
        'if ($offset !~ /^-?\d+$/) {',
            $self->_inline_throw_error(
                '"The first argument passed to substr must be an integer"'
            ) . ';',
        '}',
        'if ($length !~ /^-?\d+$/) {',
            $self->_inline_throw_error(
                '"The second argument passed to substr must be an integer"'
            ) . ';',
        '}',
    );

    if ($for_writer) {
        push @code, (
            'if (!Moose::Util::_STRINGLIKE0($replacement)) {',
                $self->_inline_throw_error(
                    '"The third argument passed to substr must be a string"'
                ) . ';',
            '}',
        );
    }

    return @code;
}

sub _potential_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '(do { '
             . 'my $potential = ' . $slot_access . '; '
             . '@return = substr $potential, $offset, $length, $replacement; '
             . '$potential; '
         . '})';
}

sub _inline_optimized_set_new_value {
    my $self = shift;
    my ($inv, $new, $slot_access) = @_;

    return '@return = substr ' . $slot_access . ', '
                           . '$offset, $length, $replacement;';
}

sub _return_value {
    my $self = shift;
    my ($slot_access, $for_writer) = @_;

    return '$return[0]' if $for_writer;

    return 'substr ' . $slot_access . ', $offset, $length';
}

no Moose::Role;

1;
