package Test::Moose;
BEGIN {
  $Test::Moose::AUTHORITY = 'cpan:STEVAN';
}
{
  $Test::Moose::VERSION = '2.1005';
}

use strict;
use warnings;

use Sub::Exporter;
use Test::Builder;

use List::MoreUtils 'all';
use Moose::Util 'does_role', 'find_meta';

my @exports = qw[
    meta_ok
    does_ok
    has_attribute_ok
    with_immutable
];

Sub::Exporter::setup_exporter({
    exports => \@exports,
    groups  => { default => \@exports }
});

## the test builder instance ...

my $Test = Test::Builder->new;

## exported functions

sub meta_ok ($;$) {
    my ($class_or_obj, $message) = @_;

    $message ||= "The object has a meta";

    if (find_meta($class_or_obj)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub does_ok ($$;$) {
    my ($class_or_obj, $does, $message) = @_;

    $message ||= "The object does $does";

    if (does_role($class_or_obj, $does)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub has_attribute_ok ($$;$) {
    my ($class_or_obj, $attr_name, $message) = @_;

    $message ||= "The object does has an attribute named $attr_name";

    my $meta = find_meta($class_or_obj);

    if ($meta->find_attribute_by_name($attr_name)) {
        return $Test->ok(1, $message)
    }
    else {
        return $Test->ok(0, $message);
    }
}

sub with_immutable (&@) {
    my $block = shift;
    my $before = $Test->current_test;
    my $passing_before = (Test::Builder->VERSION < 1.005 ? 0 : $Test->history->pass_count) || 0;

    $block->(0);
    Class::MOP::class_of($_)->make_immutable for @_;
    $block->(1);

    my $num_tests = $Test->current_test - $before;
    my $all_passed = Test::Builder->VERSION < 1.005
        ? all { $_ } ($Test->summary)[-$num_tests..-1]
        : $num_tests == $Test->history->pass_count - $passing_before;
    return $all_passed;
}

1;

# ABSTRACT: Test functions for Moose specific features

__END__

=pod

=head1 NAME

Test::Moose - Test functions for Moose specific features

=head1 VERSION

version 2.1005

=head1 SYNOPSIS

  use Test::More plan => 1;
  use Test::Moose;

  meta_ok($class_or_obj, "... Foo has a ->meta");
  does_ok($class_or_obj, $role, "... Foo does the Baz role");
  has_attribute_ok($class_or_obj, $attr_name, "... Foo has the 'bar' attribute");

=head1 DESCRIPTION

This module provides some useful test functions for Moose based classes. It
is an experimental first release, so comments and suggestions are very welcome.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<meta_ok ($class_or_object)>

Tests if a class or object has a metaclass.

=item B<does_ok ($class_or_object, $role, ?$message)>

Tests if a class or object does a certain role, similar to what C<isa_ok>
does for the C<isa> method.

=item B<has_attribute_ok($class_or_object, $attr_name, ?$message)>

Tests if a class or object has a certain attribute, similar to what C<can_ok>
does for the methods.

=item B<with_immutable { CODE } @class_names>

Runs B<CODE> (which should contain normal tests) twice, and make each
class in C<@class_names> immutable in between the two runs.

The B<CODE> block is called with a single boolean argument indicating whether
or not the classes have been made immutable yet.

=back

=head1 TODO

=over 4

=item Convert the Moose test suite to use this module.

=item Here is a list of possible functions to write

=over 4

=item immutability predicates

=item anon-class predicates

=item discovering original method from modified method

=item attribute metaclass predicates (attribute_isa?)

=back

=back

=head1 SEE ALSO

=over 4

=item L<Test::More>

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
