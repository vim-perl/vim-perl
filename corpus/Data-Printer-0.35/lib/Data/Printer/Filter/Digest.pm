package Data::Printer::Filter::Digest;
use strict;
use warnings;
use Data::Printer::Filter;
use Term::ANSIColor;

foreach my $digest ( qw( Digest::MD2 Digest::MD4 Digest::Haval256)) {
    filter $digest => \&_print_digest;
}

filter '-class', sub {
  my ($obj, $p) = @_;
  return unless $obj->isa( 'Digest::base' );
  return _print_digest( $obj, $p );
};


sub _print_digest {
  my ($obj, $p) = @_;
  my $digest = $obj->clone->hexdigest;
  my $str = $digest;
  my $ref = ref $obj;

  if ( $p->{digest}{show_class_name} ) {
      $str .= " ($ref)";
  }

  unless ( exists  $p->{digest}{show_reset}
              and !$p->{digest}{show_reset}
   ) {
     if ($digest eq $ref->new->hexdigest) {
         $str .= ' [reset]';
     }
  }

  my $color = $p->{color}{digest};
  $color = 'bright_green' unless defined $color;

  return colored( $str, $color );
}

1;

__END__

=head1 NAME

Data::Printer::Filter::Digest - pretty-printing MD5, SHA and friends

=head1 SYNOPSIS

In your program:

  use Data::Printer filters => {
    -external => [ 'Digest' ],
  };

or, in your C<.dataprinter> file:

  {
    filters => {
       -external => [ 'Digest' ],
    },
  };

You can also setup color and display details:

  use Data::Printer
      filters => {
          -external => [ 'Digest' ],
      },
      color   => {
          digest => 'bright_green',
      }
      digest => {
          show_class_name => 0,  # default.
          show_reset      => 1,  # default.
      },
  };

=head1 DESCRIPTION

This is a filter plugin for L<Data::Printer>. It filters through
several digest classes and displays their current value in
hexadecimal format as a string.

=head2 Parsed Modules

=over 4

=item * L<Digest::Adler32>

=item * L<Digest::MD2>

=item * L<Digest::MD4>

=item * L<Digest::MD5>

=item * L<Digest::SHA>

=item * L<Digest::SHA1>

=item * L<Digest::Whirlpool>

=item * L<Digest::Haval256>

=back

If you have any suggestions for more modules or better output,
please let us know.

=head2 Extra Options

Aside from the display color, there are a few other options to
be customized via the C<digest> option key:

=head3 show_class_name

Set this to true to display the class name right next to the
hexadecimal digest. Default is 0 (false).

=head3 show_reset

If set to true (the default), the filter will add a C<[reset]>
tag after dumping an empty digest object. See the rationale below.

=head2 Note on dumping Digest::* objects

The digest operation is effectively a destructive, read-once operation. Once it has been performed, most Digest::* objects are automatically reset and can be used to calculate another digest value.

This behaviour - or, rather, forgetting about this behaviour - is
a common source of issues when working with Digests.

This Data::Printer filter will B<not> destroy your object. Instead, we work on a cloned version to display the hexdigest, leaving your
original object untouched.

As another debugging convenience for developers, since the empty
object will produce a digest even after being used, this filter
adds by default a C<[reset]> tag to indicate that the object is
empty, in a 'reset' state - i.e. its hexdigest is the same as
the hexdigest of a new, empty object of that same class.

=head1 SEE ALSO

L<Data::Printer>


