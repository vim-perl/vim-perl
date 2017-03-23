package Data::Printer::Filter;
use strict;
use warnings;
use Clone::PP qw(clone);
require Carp;
require Data::Printer;

my %_filters_for   = ();
my %_extras_for    = ();

sub import {
    my $caller = caller;
    my $id = Data::Printer::_object_id( \$caller );

    my %properties = ();

    my $filter = sub {
        my ($type, $code, $extra) = @_;

        Carp::croak( "syntax: filter 'Class', sub { ... }" )
          unless $type and $code and ref $code eq 'CODE';

        if ($extra) {
            Carp::croak( 'extra filter field must be a hashref' )
                unless ref $extra and ref $extra eq 'HASH';

            $_extras_for{$id}{$type} = $extra;
        }
        else {
            $_extras_for{$id}{$type} = {};
        }

        unshift @{ $_filters_for{$id}{$type} }, sub {
            my ($item, $p) = @_;

            # send our closured %properties var instead
            # so newline(), indent(), etc can work it
            %properties = %{ clone $p };
            delete $properties{filters}; # no need to rework filters
            $code->($item, \%properties);
        };
    };

    my $filters = sub {
        return $_filters_for{$id};
    };

    my $extras = sub {
        return $_extras_for{$id};
    };

    my $newline = sub {
        return ${$properties{_linebreak}} . (' ' x $properties{_current_indent});
    };

    my $indent = sub {
        $properties{_current_indent} += $properties{indent};
        $properties{_depth}++;
        return;
    };

    my $outdent = sub {
        $properties{_current_indent} -= $properties{indent};
        $properties{_depth}--;
        return;
    };

    my $imported = sub (\[@$%&];%) {
        my ($item, $p) = @_;
        return Data::Printer::p( $item, %properties );
    };

    {
        no strict 'refs';
        *{"$caller\::filter"}  = $filter;
        *{"$caller\::indent"}  = $indent;
        *{"$caller\::outdent"} = $outdent;
        *{"$caller\::newline"} = $newline;

        *{"$caller\::p"} = $imported;

        *{"$caller\::_filter_list"}   = $filters;
        *{"$caller\::_extra_options"} = $extras;
    }
};


1;
__END__

=head1 NAME

Data::Printer::Filter - Create powerful stand-alone filters for Data::Printer

=head1 SYNOPSIS

Create your filter module:

  package Data::Printer::Filter::MyFilter;
  use strict;
  use warnings;

  use Data::Printer::Filter;

  # type filter
  filter 'SCALAR', sub {
      my ($ref, $properties) = @_;
      my $val = $$ref;
      
      if ($val > 100) {
          return 'too big!!';
      }
      else {
          return $val;
      }
  };

  # you can also filter objects of any class
  filter 'Some::Class', sub {
      my ($object, $properties) = @_;

      return $ref->some_method;   # or whatever

      # see 'HELPER FUNCTIONS' below for
      # customization options, including
      # proper indentation.
  };

  1;


Later, in your main code:

  use Data::Printer {
      filters => {
          -external => [ 'MyFilter', 'OtherFilter' ],

          # you can still add regular (inline) filters
          SCALAR => sub {
              ...
          }
      },
  };



=head1 WARNING - ALPHA CODE (VERY LOOSE API)

We are still experimenting with the standalone filter syntax, so
B<< filters written like so may break in the future without any warning! >>

B<< If you care, or have any suggestions >>, please drop me a line via RT, email,
or find me ('garu') on irc.perl.org.

You have been warned.


=head1 DESCRIPTION

L<Data::Printer> lets you add custom filters to display data structures and
objects, by either specifying them during "use", in the C<.dataprinter>
configuration file, or even in runtime customizations.

But there are times when you may want to group similar filters, or make
them standalone in order to be easily reutilized in other environments and
applications, or even upload them to CPAN so other people can benefit from
a cleaner - and clearer - object/structure dump.

This is where C<Data::Printer::Filter> comes in. It B<exports> into your
package's namespace the L</filter> function, along with some helpers to
create custom filter packages.

L<Data::Printer> recognizes all filters in the C<Data::Printer::Filter::*>
namespace. You can load them by specifying them in the '-external' filter
list (note the dash, to avoid clashing with a potential class or pragma
labelled 'external'):

  use Data::Printer {
      filters => {
          -external => 'MyFilter',
      },
  };

This will load all filters defined by the C<Data::Printer::Filter::MyFilter>
module.

If there are more than one filter, use an array reference instead:

  -external => [ 'MyFilter', 'MyOtherFilter' ]

B<< IMPORTANT: THIS WAY OF LOADING EXTERNAL PLUGINS IS EXPERIMENTAL AND
SUBJECT TO SUDDEN CHANGE! IF YOU CARE, AND/OR HAVE IDEAS ON A BETTER API,
PLEASE LET US KNOW >>

=head1 HELPER FUNCTIONS

=head2 filter TYPE, sub { ... };

The C<filter> function creates a new filter for I<TYPE>, using
the given subref. The subref receives two arguments: the item
itself - be it an object or a reference to a standard Perl type -
and the properties in effect (so you can inspect for certain
options, etc). The subroutine is expected to return a string
containing whatever it wants C<Data::Printer> to display on screen.

=head2 p()

This is the same as C<Data::Printer>'s p(), only you can't rename it.
You can use this to throw some data structures back at C<Data::Printer>
and use the results in your own return string - like when manipulating
hashes or arrays.

=head2 newline()

This helper returns a string using the linebreak as specified by the
caller's settings. For instance, it provides the proper indentation
level of spaces for you and considers the C<multiline> option to
avoid line breakage.

In other words, if you do this:

   filter ARRAY => {
       my ($ref, $p) = @_;
       my $string = "Hey!! I got this array:";

       foreach my $val (@$ref) {
           $string .= newline . p($val);
       }

       return $string;
   };

... your C<p($val)> returns will be properly indented, vertically aligned
to your level of the data structure, while simply using "\n" would just
make things messy if your structure has more than one level of depth.

=head2 indent()

=head2 outdent()

These two helpers let you increase/decrease the indentation level of
your data display, for C<newline()> and nested C<p()> calls inside your filters.

For example, the filter defined in the C<newline> explanation above would
show the values on the same (vertically aligned) level as the "I got this array"
message. If you wanted your array to be one level further deep, you could use
this instead:

  filter ARRAY => {
      my ($ref, $p) = @_;
      my $string = "Hey!! I got this array:";

      indent;
      foreach my $val (@$ref) {
          $string .= newline . p($val);
      }
      outdent;

      return $string;
  };


=head1 COLORIZATION

You can use L<Term::ANSIColor>'s C<colored()>' for string
colorization. Data::Printer will automatically enable/disable
colors for you.

=head1 EXISTING FILTERS

This is meant to provide a complete list of standalone filters for
Data::Printer available on CPAN. If you write one, please put it under
the C<Data::Printer::Filter::*> namespace, and drop me a line so I can
add it to this list!

=head2 Databases

L<Data::Printer::Filter::DB> provides filters for Database objects. So
far only DBI is covered, but more to come!

=head2 Dates & Times

L<Data::Printer::Filter::DateTime> pretty-prints several date
and time objects (not just DateTime) for you on the fly, including
duration/delta objects!

=head2 Digest

L<Data::Printer::Filter::Digest> displays a string containing the
hash of the actual message digest instead of the object. Works on
C<Digest::MD5>, C<Digest::SHA>, any digest class that inherits from
C<Digest::base> and some others that implement their own thing!

=head2 ClassicRegex

L<Data::Printer::Filter::ClassicRegex> changes the way Data::Printer
dumps regular expressions, doing it the classic C<qr//> way that got
popular in C<Data::Dumper>.

=head2 URI

L<Data::Printer::Filter::URI> pretty-prints L<URI> objects, displaying
the URI as a string instead of dumping the object.

=head2 JSON

L<Data::Printer::Filter::JSON> lets you see your JSON structures
replacing boolean objects with simple C<true/false> strings!

=head2 URIs

L<Data::Printer::Filter::URI> filters through several L<URI> manipulation
classes and displays the URI as a colored string. A very nice addition
by Stanislaw Pusep (SYP).

=head1 USING MORE THAN ONE FILTER FOR THE SAME TYPE/CLASS

As of version 0.13, standalone filters let you stack together
filters for the same type or class. Filters of the same type are
called in order, until one of them returns a string. This lets
you have several filters inspecting the same given value until
one of them decides to actually treat it somehow.

If your filter catched a value and you don't want to treat it,
simply return and the next filter will be called. If there are no
other filters for that particular class or type available, the
standard Data::Printer calls will be used.

For example:

  filter SCALAR => sub {
      my ($ref, $properties) = @_;
      if ( Scalar::Util::looks_like_number $$ref ) {
          return sprintf "%.8d", $$ref;
      }
      return; # lets the other SCALAR filter have a go
  };

  filter SCALAR => sub {
      my ($ref, $properties) = @_;
      return qq["$$ref"];
  };

Note that this "filter stack" is not possible on inline filters, since
it's a hash and keys with the same name are overwritten. Instead, you
can pass them as an array reference:

  use Data::Printer filters => {
      SCALAR => [ sub { ... }, sub { ... } ],
  };


=head1 SEE ALSO

L<Data::Printer>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


