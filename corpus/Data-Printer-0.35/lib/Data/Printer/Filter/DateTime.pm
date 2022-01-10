package Data::Printer::Filter::DateTime;
use strict;
use warnings;
use Data::Printer::Filter;
use Term::ANSIColor;

filter 'Time::Piece', sub {
    return _format($_[0]->cdate, @_ );
};

filter 'DateTime', sub {
    my ($obj, $p) = @_;
    my $string = "$obj";
    if ( not exists $p->{datetime}{show_timezone} or $p->{datetime}{show_timezone} ) {
        $string .= ' [' . $obj->time_zone->name . ']';
    }
    return _format( $string, @_ );
};

# DateTime::TimeZone filters
filter '-class' => sub {
    my ($obj, $properties) = @_;

    if ( $obj->isa('DateTime::TimeZone' ) ) {
        return $obj->name;
    }
    else {
        return;
    }
};

filter 'DateTime::Incomplete', sub {
    return _format( $_[0]->iso8601, @_ );
};

filter 'DateTime::Duration', sub {
    my ($object, $p) = @_;

    my @dur = $object->in_units(
         qw(years months days hours minutes seconds)
    );

    my $string = "$dur[0]y $dur[1]m $dur[2]d $dur[3]h $dur[4]m $dur[5]s";

    return _format( $string, @_ );
};

filter 'DateTime::Tiny', sub {
    return _format( $_[0]->as_string, @_ );
};

filter 'Date::Calc::Object', sub {
    return _format( $_[0]->string(2), @_ );
};

filter 'Date::Pcalc::Object', sub {
    return _format( $_[0]->string(2), @_ );
};

filter 'Date::Handler', sub {
    return _format( "$_[0]", @_ );
};

filter 'Date::Handler::Delta', sub {
    return _format( $_[0]->AsScalar, @_ );
};


sub _format {
    my ($str, $obj, $p) = @_;

    if ( $p->{datetime}{show_class_name} ) {
        $str .= ' (' . ref($obj) . ')';
    }

    my $color = $p->{color}{datetime};
    $color = 'bright_green' unless defined $color;

    return colored( $str, $color );
}

1;

__END__

=head1 NAME

Data::Printer::Filter::DateTime - pretty-printing date and time objects (not just DateTime!)

=head1 SYNOPSIS

In your program:

  use Data::Printer filters => {
    -external => [ 'DateTime' ],
  };

or, in your C<.dataprinter> file:

  {
    filters => {
       -external => [ 'DateTime' ],
    },
  };

You can also setup color and display details:

  use Data::Printer
      filters => {
          -external => [ 'DateTime' ],
      },
      color   => {
          datetime => 'bright_green',
      }
      datetime => {
          show_class_name => 1,  # default is 0
          show_timezone   => 0,  # default is 1 (only works for DateTime objects)
      },
  };

=head1 DESCRIPTION

This is a filter plugin for L<Data::Printer>. It filters through
several date and time manipulation classes and displays the time
(or time duration) as a string.

=head2 Parsed Modules

=over 4

=item * L<DateTime>

=item * L<DateTime::Duration>

=item * L<DateTime::Incomplete>

=item * L<Time::Piece>

=item * L<Date::Handler>

=item * L<Date::Handler::Delta>

=item * L<Date::Calc::Object>

=item * L<Date::Pcalc::Object>

=back

If you have any suggestions for more modules or better output,
please let us know.


=head1 SEE ALSO

L<Data::Printer>


