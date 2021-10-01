#!/usr/local/bin/perl
# From http://www.van-laarhoven.org/vim/syntax/perl.vim.regression.pl
# Regression tests for the perl.vim file
# Please run this one first before committing any patches.

# //

$a /= 2;
if (/hello/) {
   $b = 2;
}

$a =~ / hello/;
$a /= /hello/x;
$a = 1/$hello / 2/4;


$a = new HelloWorld::Thing;

package HelloWorld;

sub new {
	my ($class) = @_;

	return bless {}, $class;
}

1;

# Test for here document. EOF should be coloured as string or as statement
# depending on whether perl_string_as_statement is set.
# XXX 'if $true' is highlighted incorrectly
$true = 1;
print <<EOF if $true;
Here document
EOF
print <<"EOF" if $true;
Here document
EOF
print <<'EOF' if $true;
Here document
EOF
print <<`EOF` if $true;
Here document
EOF

# Here documents finishing with an empty line. Note the Error colour because of
# the line with only a space in it.
print <<"" if $true;
Here document
 

print <<'' if $true;
Here document
 

print <<`` if $true;
Here document
 

# Here document with a different. Only works in 6.0.
print <<RandomID;
here document
RandomID

do {
    print <<'EOF' if $true;
    Here document
    EOF
$true
EOF
}

# Don't fold
#
sub x;

sub x { print "x"; }

sub y($);

sub y($) { print "y"; }

# Fold
#
sub y ($) {
        print "y";
}

sub y($)
{
        print "y";
}

sub x {
        print "x";
}

sub x
{
        print "x";
}

BEGIN {
        sub x {
                print "x";
        }
}

# todo notes
# TODO line without colon
# TODO: line with colon

# Fold the DATA segment
# XXX We should add some POD to show that that is highlighted correctly as well
#     in there.
#
__DATA__

hello world
