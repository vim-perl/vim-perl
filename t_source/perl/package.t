package Testing::Only;

my $variable;


package Testing::WithVersion 1.2;

package My::Class {
    our $task = "testing";
}

package My::OtherClass 1.0 {
    sub activate {
        say "activated";
    }
}

package main;
# back where we started.
