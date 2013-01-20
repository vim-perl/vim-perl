package VimFolds;

use strict;
use warnings;
use autodie;
use parent 'Exporter';

use Carp qw(croak);
use IO::Pty;
use File::Temp;

use Test::More;
use Test::Deep;

sub new {
    my ( $class, %params ) = @_;

    return bless { %params }, $class;
}

sub _get_folds {
    my ( $self, $filename ) = @_;

    my $script_before = $self->{'script_before'} || '';
    my $syntax_file   = 'syntax/' . $self->{'language'} . '.vim';

    my $script_file    = File::Temp->new(SUFFIX => '.vim');
    my $dump_file      = File::Temp->new;
    close $dump_file;
    my $dump_file_name = $dump_file->filename;

    print { $script_file } <<"END_VIM";
$script_before

source $syntax_file

function DumpFoldsAndQuit()
    let folds          = []
    let num_lines      = line('\$')
    let max_fold_level = -1

    let line_num = 1

    while line_num <= num_lines
        let line_num = line_num + 1

        let fold_level = foldlevel(line_num)

        if fold_level > max_fold_level
            let max_fold_level = fold_level
        endif
    endwhile

    let fold_level = max_fold_level

    while fold_level >= 0
        let &foldlevel = fold_level
        let line_num   = 1

        while line_num <= num_lines
            let fold_start = foldclosed(line_num)

            if fold_start == -1
                let line_num = line_num + 1
            else
                let fold_end = foldclosedend(line_num)

                call add(folds, join([ fold_start, fold_end, &foldlevel ], ','))

                let line_num = fold_end + 1
            endif
        endwhile

        let fold_level = fold_level - 1
    endwhile

    call writefile(folds, '$dump_file_name')
    quit
endfunction
END_VIM

    my $pty = IO::Pty->new;
    my $pid = fork;

    croak "Unable to fork" unless defined $pid;

    if($pid) {
        $pty->close_slave;
        $pty->set_raw;
        sleep 1; # wait for folds to be set up
        print { $pty } ":call DumpFoldsAndQuit()\n";
        while(<$pty>) {
            # just read until the child is done
        }
        close $pty;
        waitpid $pid, 0;
    } else {
        $pty->make_slave_controlling_terminal;
        my $slave = $pty->slave;
        $slave->clone_winsize_from(\*STDIN);
        $slave->set_raw;

        open STDIN,  '<&', $slave->fileno;
        open STDOUT, '>&', $slave->fileno;
        open STDERR, '>&', $slave->fileno;

        close $slave;

        exec 'vim', '-u', $script_file->filename, $filename;
    }

    my @folds;

    my $fh;

    open $fh, '<', $dump_file_name;
    while(<$fh>) {
        chomp;

        my ( $start, $end, $level ) = split /,/;
        push @folds, {
            start => $start,
            end   => $end,
            level => $level,
        };
    }
    close $fh;

    return @folds;
}

sub _find_expected_folds {
    my ( $self, $filename ) = @_;

    my @folds;
    my @fold_stack;

    my $fh;

    open $fh, '<', $filename;
    while(<$fh>) {
        chomp;

        if(/\Q{{{\E/) {
            push @fold_stack, $.;
        } elsif(/\Q}}}\E/) {
            my $start = pop @fold_stack;
            push @folds, {
                start => $start,
                end   => $.,
            };
        }
    }
    close $fh;

    return @folds;
}

sub folds_match {
    my ( $self, $code ) = @_;

    my $tempfile = File::Temp->new;
    print { $tempfile } $code;
    close $tempfile;

    my @expected_folds = $self->_find_expected_folds($tempfile->filename);
    my @got_folds      = $self->_get_folds($tempfile->filename);

    foreach my $fold (@got_folds) {
        delete $fold->{'level'};
    }
    local $Test::Builder::Level =  $Test::Builder::Level + 1;

    unless(cmp_set(\@got_folds, \@expected_folds)) {
        diag('Got: ' . join('', explain(\@got_folds)));
        diag('Expected: ' . join('', explain(\@expected_folds)));
    }
}

1;
