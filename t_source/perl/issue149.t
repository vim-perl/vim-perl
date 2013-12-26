#!/usr/bin/env perl

BEGIN {
    my $a = sub {

    };
}

around fff => sub {    #comment } {

    #if (1) {
    #
    #
    #
    #}

};

sub aa_111_DDDF_vvv {    #comment } {

    my $b = {            #comment } {
        aaa => 1111,
        ccc => sub {

            #if (1) {
            #
            #
            #
            #}
        },
        bbb => 222
    };

    my $a = sub {

        #if (1) {
        #
        #
        #
        #}

    };

    #if (1) {
    #
    #
    #
    #}

}

my $a = sub {    #comment } {

    #if (1) {
    #
    #
    #
    #}

    my $b = sub {    #comment } {

        #if (1) {
        #
        #
        #
        #}

    };

};

__END__
## -----SOURCE FILTER LOG BEGIN-----
## 
## 1 -   19 - NamingConventions::Capitalization - Subroutine "aa_111_DDDF_vvv" is not all lower case or all upper case
## 
## 2 -    1 - Modules::RequireVersionVar - No package-scoped "$VERSION" variable found
## 
## 4 -   19 - Subroutines::RequireFinalReturn - Subroutine "aa_111_DDDF_vvv" does not end with "return"
## 
## 4 -    3 - TestingAndDebugging::RequireUseWarnings - Code before warnings are enabled
## 
## 5 -    3 - TestingAndDebugging::RequireUseStrict - Code before strictures are enabled
## 
## -----SOURCE FILTER LOG END-----
