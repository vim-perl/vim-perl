#!/usr/bin/env perl

use warnings FATAL => 'all';
use strict;
use File::Temp;
use Path::Class;

my $number_of_classes = shift || 1500;
my $number_of_attributes = shift || 20;
my $t = shift || File::Temp->newdir;
my $tmp = dir($t);
$tmp->rmtree;
$tmp->mkpath;
(-d $tmp) or die "not a dir: $tmp";
#print "$tmp\n";

my %class_writer = (
    'Moose' => sub {
        my $name = shift;
        my $attrs = join '', map { "has '$_' => ( is => 'ro', isa => 'Str' );\n" } @_;
        return qq{package $name;\nuse Moose;\n$attrs\n1;\n__END__\n};
    },
    'MooseImmutable' => sub {
        my $name = shift;
        my $attrs = join '', map { "has '$_' => ( is => 'ro', isa => 'Str' );\n" } @_;
        return qq{package $name;\nuse Moose;\n$attrs\n__PACKAGE__->meta->make_immutable;\n1;\n__END__\n};
    },
    'Moo' => sub {
        my $name = shift;
        my $attrs = join'', map { "has '$_' => ( is => 'ro', isa => 'Str' );\n" } @_;
        return qq{package $name;\nuse Moo;\n$attrs\n1;\n__END__\n};
    },
    'Mo' => sub {
        my $name = shift;
        my $attrs = join'', map { "has '$_' => ( is => 'ro', isa => 'Str' );\n" } @_;
        return qq{package $name;\nuse Mo;\n$attrs\n1;\n__END__\n};
    },
    'Mouse' => sub {
        my $name = shift;
        my $attrs = join'', map { "has '$_' => ( is => 'ro', isa => 'Str' );\n" } @_;
        return qq{package $name;\nuse Mouse;\n$attrs\n1;\n__END__\n};
    },
    'plain-package' => sub {
        my $name = shift;
        my $attrs = join'', map { "sub $_ {}\n" } @_;
        return qq{package $name;\n$attrs\n1;\n__END__\n};
    },
);

my $class_prefix = 'TmpClassThingy';
my %lib_map;
my @attribute_names = map { 'a' . $_ } 1 .. $number_of_attributes;
for my $module (sort keys %class_writer) {
    my $lib = $tmp->subdir($module . '-lib');
    $lib->mkpath;
    my $all_fh = $lib->file('All.pm')->openw;
    for my $n (1 .. $number_of_classes) {
        my $class_name = $class_prefix . $n;
        my $fh = $lib->file($class_name . '.pm')->openw;
        $fh->say($class_writer{$module}->($class_name, @attribute_names)) or die;
        $fh->close or die;
        $all_fh->say("use $class_name;") or die;
    }
    $all_fh->say('1;') or die;
    $all_fh->close or die;
    $lib_map{$module} = $lib;
}

#$DB::single = 1;
for my $module (sort keys %lib_map) {
    my $lib = $lib_map{$module};
    print "$module\n";
    my $cmd = "time -p $^X -I$lib -MAll -e '1'";
    `$cmd > /dev/null 2>&1`; # to cache
#    print "$cmd\n";
    system($cmd);
    print "\n";
}

