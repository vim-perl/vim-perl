package Moose::Meta::Attribute::Native::Trait::Number;
BEGIN {
  $Moose::Meta::Attribute::Native::Trait::Number::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Attribute::Native::Trait::Number::VERSION = '2.1005';
}
use Moose::Role;

with 'Moose::Meta::Attribute::Native::Trait';

sub _helper_type { 'Num' }

no Moose::Role;

1;

# ABSTRACT: Helper trait for Num attributes

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::Number - Helper trait for Num attributes

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  package Real;
  use Moose;

  has 'integer' => (
      traits  => ['Number'],
      is      => 'ro',
      isa     => 'Num',
      default => 5,
      handles => {
          set => 'set',
          add => 'add',
          sub => 'sub',
          mul => 'mul',
          div => 'div',
          mod => 'mod',
          abs => 'abs',
      },
  );

  my $real = Real->new();
  $real->add(5);    # same as $real->integer($real->integer + 5);
  $real->sub(2);    # same as $real->integer($real->integer - 2);

=head1 DESCRIPTION

This trait provides native delegation methods for numbers. All of the
operations correspond to arithmetic operations like addition or
multiplication.

=head1 DEFAULT TYPE

If you don't provide an C<isa> value for your attribute, it will default to
C<Num>.

=head1 PROVIDED METHODS

All of these methods modify the attribute's value in place. All methods return
the new value.

=over 4

=item * B<add($value)>

Adds the current value of the attribute to C<$value>.

=item * B<sub($value)>

Subtracts C<$value> from the current value of the attribute.

=item * B<mul($value)>

Multiplies the current value of the attribute by C<$value>.

=item * B<div($value)>

Divides the current value of the attribute by C<$value>.

=item * B<mod($value)>

Returns the current value of the attribute modulo C<$value>.

=item * B<abs>

Sets the current value of the attribute to its absolute value.

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
