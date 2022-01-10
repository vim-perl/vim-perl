package Moose::Meta::Method::Accessor::Native::String::replace;
BEGIN {
  $Moose::Meta::Method::Accessor::Native::String::replace::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Method::Accessor::Native::String::replace::VERSION = '2.1005';
}

use strict;
use warnings;

use Moose::Util ();
use Params::Util ();

use Moose::Role;

with 'Moose::Meta::Method::Accessor::Native::Writer';

sub _minimum_arguments { 1 }

sub _maximum_arguments { 2 }

sub _inline_check_arguments {
    my $self = shift;

    return (
        'if (!Moose::Util::_STRINGLIKE0($_[0]) && !Params::Util::_REGEX($_[0])) {',
            $self->_inline_throw_error(
                '"The first argument passed to replace must be a string or '
              . 'regexp reference"'
            ) . ';',
        '}',
        'if (!Moose::Util::_STRINGLIKE0($_[1]) && !Params::Util::_CODELIKE($_[1])) {',
            $self->_inline_throw_error(
                '"The second argument passed to replace must be a string or '
              . 'code reference"'
            ) . ';',
        '}',
    );
}

sub _potential_value {
    my $self = shift;
    my ($slot_access) = @_;

    return '(do { '
             . 'my $val = ' . $slot_access . '; '
             . 'ref $_[1] '
                 . '? $val =~ s/$_[0]/$_[1]->()/e '
                 . ': $val =~ s/$_[0]/$_[1]/; '
             . '$val; '
         . '})';
}

sub _inline_optimized_set_new_value {
    my $self = shift;
    my ($inv, $new, $slot_access) = @_;

    return (
        'ref $_[1]',
            '? ' . $slot_access . ' =~ s/$_[0]/$_[1]->()/e',
            ': ' . $slot_access . ' =~ s/$_[0]/$_[1]/;',
     );
}

no Moose::Role;

1;
