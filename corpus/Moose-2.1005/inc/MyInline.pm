package MyInline;

use strict;
use warnings;

{
    package My::Extract;

    use base 'Test::Inline::Extract';

    use List::Util qw( first );

    # This extracts the SYNOPSIS in addition to code specifically
    # marked for testing
    my $search = qr/
        (?:^|\n)                           # After the beginning of the string, or a newline
        (                                  # ... start capturing
                                           # EITHER
            package\s+                            # A package
            [^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*    # ... with a name
            \s*;                                  # And a statement terminator
                |
                        =head1[ \t]+SYNOPSIS\n
                        .*?
                        (?=\n=)
        |                                  # OR
            =for[ \t]+example[ \t]+begin\n        # ... when we find a =for example begin
            .*?                                   # ... and keep capturing
            \n=for[ \t]+example[ \t]+end\s*?      # ... until the =for example end
            (?:\n|$)                              # ... at the end of file or a newline
        |                                  # OR
            =begin[ \t]+(?:test|testing)(?:-SETUP)? # ... when we find a =begin test or testing
            .*?                                     # ... and keep capturing
            \n=end[ \t]+(?:test|testing)(?:-SETUP)? # ... until an =end tag
                        .*?
            (?:\n|$)                              # ... at the end of file or a newline
        )                                  # ... and stop capturing
        /isx;

    sub _elements {
        my $self     = shift;
        my @elements = ();
        while ( $self->{source} =~ m/$search/go ) {
            my $elt = $1;

            # A hack to turn the SYNOPSIS into something Test::Inline
            # doesn't barf on
            if ( $elt =~ s/=head1[ \t]+SYNOPSIS/=begin testing-SETUP\n\n{/ ) {
                $elt .= "}\n\n=end testing-SETUP";
            }

            # It seems like search.cpan doesn't like a name with
            # spaces after =begin. bleah, what a mess.
            $elt =~ s/testing-SETUP/testing SETUP/g;

            push @elements, $elt;
        }

        # If we have just one element it's a SYNOPSIS, so there's no
        # tests.
        return unless @elements > 2;

        if ( @elements && $self->{source} =~ /=head1 NAME\n\n(Moose::Cookbook\S+)/ ) {
            unshift @elements, 'package ' . $1 . ';';
        }

        ( first {/^=/} @elements ) ? \@elements : '';
    }
}

{
    package My::Content;

    use base 'Test::Inline::Content::Default';

    sub process {
        my $self = shift;

        my $base = $self->SUPER::process(@_);

        $base =~ s/(\$\| = 1;)/use Test::Fatal;\n$1/;

        return $base;
    }
}

1;
