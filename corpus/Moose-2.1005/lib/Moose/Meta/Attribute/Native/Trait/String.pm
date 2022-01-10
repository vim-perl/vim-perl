package Moose::Meta::Attribute::Native::Trait::String;
BEGIN {
  $Moose::Meta::Attribute::Native::Trait::String::AUTHORITY = 'cpan:STEVAN';
}
{
  $Moose::Meta::Attribute::Native::Trait::String::VERSION = '2.1005';
}
use Moose::Role;

with 'Moose::Meta::Attribute::Native::Trait';

sub _default_default { q{} }
sub _default_is { 'rw' }
sub _helper_type { 'Str' }

no Moose::Role;

1;

# ABSTRACT: Helper trait for Str attributes

__END__

=pod

=head1 NAME

Moose::Meta::Attribute::Native::Trait::String - Helper trait for Str attributes

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  package MyHomePage;
  use Moose;

  has 'text' => (
      traits  => ['String'],
      is      => 'rw',
      isa     => 'Str',
      default => q{},
      handles => {
          add_text     => 'append',
          replace_text => 'replace',
      },
  );

  my $page = MyHomePage->new();
  $page->add_text("foo");    # same as $page->text($page->text . "foo");

=head1 DESCRIPTION

This trait provides native delegation methods for strings.

=head1 DEFAULT TYPE

If you don't provide an C<isa> value for your attribute, it will default to
C<Str>.

=head1 PROVIDED METHODS

=over 4

=item * B<inc>

Increments the value stored in this slot using the magical string autoincrement
operator. Note that Perl doesn't provide analogous behavior in C<-->, so
C<dec> is not available. This method returns the new value.

This method does not accept any arguments.

=item * B<append($string)>

Appends to the string, like C<.=>, and returns the new value.

This method requires a single argument.

=item * B<prepend($string)>

Prepends to the string and returns the new value.

This method requires a single argument.

=item * B<replace($pattern, $replacement)>

Performs a regexp substitution (L<perlop/s>). There is no way to provide the
C<g> flag, but code references will be accepted for the replacement, causing
the regex to be modified with a single C<e>. C</smxi> can be applied using the
C<qr> operator. This method returns the new value.

This method requires two arguments.

=item * B<match($pattern)>

Runs the regex against the string and returns the matching value(s).

This method requires a single argument.

=item * B<chop>

Just like L<perlfunc/chop>. This method returns the chopped character.

This method does not accept any arguments.

=item * B<chomp>

Just like L<perlfunc/chomp>. This method returns the number of characters
removed.

This method does not accept any arguments.

=item * B<clear>

Sets the string to the empty string (not the value passed to C<default>).

This method does not have a defined return value.

This method does not accept any arguments.

=item * B<length>

Just like L<perlfunc/length>, returns the length of the string.

=item * B<substr>

This acts just like L<perlfunc/substr>. When called as a writer, it returns
the substring that was replaced, just like the Perl builtin.

This method requires at least one argument, and accepts no more than three.

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
