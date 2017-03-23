package DDP;
use strict;
use warnings;
use Data::Printer;

BEGIN {
    push our @ISA, 'Data::Printer';
    our $VERSION = $Data::Printer::VERSION;
}
1;
__END__

=head1 NAME

DDP - Data::Printer shortcut for faster debugging

=head1 SYNOPSIS

  use DDP; p $my_data;

=head1 DESCRIPTION

Tired of typing C<use Data::Printer> every time? C<DDP> lets you quickly call
your favorite variable dumper!

It behaves exacly like L<Data::Printer> - it is, indeed, just an alias to it :)

Happy debugging!

=head1 SEE ALSO

L<Data::Printer>

