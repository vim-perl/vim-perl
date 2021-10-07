# vim:ft=perl

# Source: perldata

# Numeric literals are specified in any of the following floating point or
# integer formats:

.23E-10            # a very small number
3.14_15_92         # a very important number
4_294_967_296      # underscore for legibility
0xff               # hex
0xdead_beef        # more hex
0377               # octal (only numbers, begins with 0)
0o12_345           # alternative octal (introduced in Perl 5.33.5)
0b011011           # binary
0x1.999ap-4        # hexadecimal floating point (the 'p' is required)
