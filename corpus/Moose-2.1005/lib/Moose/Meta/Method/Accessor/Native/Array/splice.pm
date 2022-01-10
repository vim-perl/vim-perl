package Moose::Meta::Method::Accessor::Native::Array::splice;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::Array::splice::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::Array::splice::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Array::Writer';

sub _minimum_arguments { 1 }

sub _adds_members { 1 }

sub _inline_process_arguments {
    return (
        'my $idx = shift;',
        'my $len = @_ ? shift : undef;',
    );
}

sub _inline_check_arguments {
    my $self = shift;

    return (
        $self->_inline_check_var_is_valid_index('$idx'),
        'if (defined($len) && $len !~ /^-?\d+$/) {',
            $self->_inline_throw_error(
                '"The length argument passed to splice must be an integer"',
            ) . ';',
        '}',
    );
}

sub _potential_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '(do { '
             . 'my @potential = @{ (' . $slot_access . ') }; '
             . '@return = defined $len '
                 . '? (splice @potential, $idx, $len, @_) '
                 . ': (splice @potential, $idx); '
                 . '\@potential;'
         . '})';
}

sub _inline_optimized_set_new_value {
    my $self = shift;
    my ($inv, $new, $slot_access) = @_;

    return (
        '@return = defined $len',
            '? (splice @{ (' . $slot_access . ') }, $idx, $len, @_)',
            ': (splice @{ (' . $slot_access . ') }, $idx);',
    );
}

sub _return_value {
    my $self = shift;
    my ($slot_access) = @_;

    return 'wantarray ? @return : $return[-1]';
}

no Moose::Role;

1;
