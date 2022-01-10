
package Moose::Meta::Attribute::Native::Trait::Hash;
BEGIN {
  $Moose::Meta::Attribute::Native::Trait::Hash::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Attribute::Native::Trait::Hash::VERSION = '2.1005';
}
use Moose::Role;

with 'Moose::Meta::Attribute::Native::Trait';

sub _helper_type { 'HashRef' }

no Moose::Role;

1;

# ABSTRACT: Helper trait for HashRef attributes

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::Hash - Helper trait for HashRef attributes

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  package Stuff;
  use Moose;

  has 'options' => (
      traits    => ['Hash'],
      is        => 'ro',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      handles   => {
          set_option     => 'set',
          get_option     => 'get',
          has_no_options => 'is_empty',
          num_options    => 'count',
          delete_option  => 'delete',
          option_pairs   => 'kv',
      },
  );

=head1 DESCRIPTION

This trait provides native delegation methods for hash references.

=head1 PROVIDED METHODS

=over 4

=item B<get($key, $key2, $key3...)>

Returns values from the hash.

In list context it returns a list of values in the hash for the given keys. In
scalar context it returns the value for the last key specified.

This method requires at least one argument.

=item B<set($key =E<gt> $value, $key2 =E<gt> $value2...)>

Sets the elements in the hash to the given values. It returns the new values
set for each key, in the same order as the keys passed to the method.

This method requires at least two arguments, and expects an even number of
arguments.

=item B<delete($key, $key2, $key3...)>

Removes the elements with the given keys.

In list context it returns a list of values in the hash for the deleted
keys. In scalar context it returns the value for the last key specified.

=item B<keys>

Returns the list of keys in the hash.

This method does not accept any arguments.

=item B<exists($key)>

Returns true if the given key is present in the hash.

This method requires a single argument.

=item B<defined($key)>

Returns true if the value of a given key is defined.

This method requires a single argument.

=item B<values>

Returns the list of values in the hash.

This method does not accept any arguments.

=item B<kv>

Returns the key/value pairs in the hash as an array of array references.

  for my $pair ( $object->option_pairs ) {
      print "$pair->[0] = $pair->[1]\n";
  }

This method does not accept any arguments.

=item B<elements>

Returns the key/value pairs in the hash as a flattened list..

This method does not accept any arguments.

=item B<clear>

Resets the hash to an empty value, like C<%hash = ()>.

This method does not accept any arguments.

=item B<count>

Returns the number of elements in the hash. Also useful for not empty:
C<< has_options => 'count' >>.

This method does not accept any arguments.

=item B<is_empty>

If the hash is populated, returns false. Otherwise, returns true.

This method does not accept any arguments.

=item B<accessor($key)>

=item B<accessor($key, $value)>

If passed one argument, returns the value of the specified key. If passed two
arguments, sets the value of the specified key.

When called as a setter, this method returns the value that was set.

=item B<shallow_clone>

This method returns a shallow clone of the hash reference.  The return value
is a reference to a new hash with the same keys and values.  It is I<shallow>
because any values that were references in the original will be the I<same>
references in the clone.

=back

Note that C<each> is deliberately omitted, due to its stateful interaction
with the hash iterator. C<keys> or C<kv> are much safer.

=head1 METHODS

=over 4

=item B<meta>

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
