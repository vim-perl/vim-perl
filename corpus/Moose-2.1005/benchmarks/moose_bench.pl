#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes 'time';
use List::Util 'sum';
use IPC::System::Simple 'system';
use autodie;
use Parse::BACKPAN::Packages;
use LWP::Simple;
use Archive::Tar;
use File::Slurp 'slurp';

my $backpan = Parse::BACKPAN::Packages->new;
my @cmops   = $backpan->distributions('Class-MOP');
my @mooses  = $backpan->distributions('Moose');

my $cmop_version = 0;
my $cmop_dir;

my $base = "http://backpan.cpan.org/";

my %time;
my %mem;

open my $output, ">", "moose_bench.txt";

for my $moose (@mooses) {
    my $moose_dir = build($moose);

    # Find the CMOP dependency
    my $makefile = slurp("$moose_dir/Makefile.PL");
    my ($cmop_dep) = $makefile =~ /Class::MOP.*?([0-9._]+)/
        or die "Unable to find Class::MOP version dependency in $moose_dir/Makefile.PL";

    # typo?
    $cmop_dep = '0.64_07' if $cmop_dep eq '0.6407';

    # nonexistent dev releases?
    $cmop_dep = '0.79' if $cmop_dep eq '0.78_02';
    $cmop_dep = '0.83' if $cmop_dep eq '0.82_01';

    bump_cmop($cmop_dep, $moose);

    warn "Building $moose_dir";
    eval {
        system("(cd '$moose_dir' && '$^X' '-I$cmop_dir/lib' Makefile.PL && make && sudo make install) >/dev/null");

        my @times;
        for (1 .. 5) {
            my $start = time;
            system(
                $^X,
                "-I$moose_dir/lib",
                "-I$cmop_dir/lib",
                '-e', 'package Class; use Moose;',
            );
            push @times, time - $start;
        }

        $time{$moose->version} = sum(@times) / @times;
        $mem{$moose->version} = qx[$^X -I$moose_dir/lib -I$cmop_dir/lib -MGTop -e 'my (\$gtop, \$before); BEGIN { \$gtop = GTop->new; \$before = \$gtop->proc_mem(\$\$)->size; } package Class; use Moose; print \$gtop->proc_mem(\$\$)->size - \$before'];
        my $line = sprintf "%7s: %0.4f (%s), %d bytes\n",
            $moose->version,
            $time{$moose->version},
            join(', ', map { sprintf "%0.4f", $_ } @times),
            $mem{$moose->version};
        print $output $line;
    };
    warn $@ if $@;
}

require Chart::Clicker;
require Chart::Clicker::Data::Series;
require Chart::Clicker::Data::DataSet;
my @versions = sort keys %time;
my @startups = map {     $time{$_}        } @versions;
my @memories = map { int($mem{$_} / 1024) } @versions;
my @keys     = (0..$#versions);
my $cc = Chart::Clicker->new(width => 900, height => 400);
my $sutime = Chart::Clicker::Data::Series->new(
    values => \@startups,
    keys   => \@keys,
    name   => 'Startup Time',
);
my $def = $cc->get_context('default');
$def->domain_axis->tick_values(\@keys);
$def->domain_axis->tick_labels(\@versions);
$def->domain_axis->tick_label_angle(1.57);
$def->domain_axis->tick_font->size(8);
$def->range_axis->fudge_amount('0.05');

my $context = Chart::Clicker::Context->new(name => 'memory');
$context->range_axis->tick_values([qw(1024 2048 3072 4096 5120)]);
$context->range_axis->format('%d');
$context->domain_axis->hidden(1);
$context->range_axis->fudge_amount('0.05');
$cc->add_to_contexts($context);

my $musage = Chart::Clicker::Data::Series->new(
    values => \@memories,
    keys => \@keys,
    name => 'Memory Usage (kb)'
);

my $ds1 = Chart::Clicker::Data::DataSet->new(series => [ $sutime ]);
my $ds2 = Chart::Clicker::Data::DataSet->new(series => [ $musage ]);
$ds2->context('memory');

$cc->add_to_datasets($ds1);
$cc->add_to_datasets($ds2);
$cc->write_output('moose_bench.png');

sub bump_cmop {
    my $expected = shift;
    my $moose = shift;

    return $cmop_dir if $cmop_version eq $expected;

    my @orig_cmops = @cmops;
    shift @cmops until !@cmops || $cmops[0]->version eq $expected;

    die "Ran out of cmops, wanted $expected for "
        . $moose->distvname
        . " (had " . join(', ', map { $_->version } @orig_cmops) . ")"
            if !@cmops;

    $cmop_version = $cmops[0]->version;
    $cmop_dir = build($cmops[0]);

    warn "Building $cmop_dir";
    system("(cd '$cmop_dir' && '$^X' Makefile.PL && make && sudo make install) >/dev/null");

    return $cmop_dir;
}

sub build {
    my $dist = shift;
    my $distvname = $dist->distvname;
    return $distvname if -d $distvname;

    warn "Downloading $distvname";
    my $tarball = get($base . $dist->prefix);
    open my $handle, '<', \$tarball;

    my $tar = Archive::Tar->new;
    $tar->read($handle);
    $tar->extract;

    my ($arbitrary_file) = $tar->list_files;
    (my $directory = $arbitrary_file) =~ s{/.*}{};
    return $directory;
}

