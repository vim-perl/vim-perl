
package BinaryTree;

use strict;
use warnings;
use Carp qw/confess/;

use metaclass;

our $VERSION = '0.02';

BinaryTree->meta->add_attribute('uid' => (
    reader  => 'getUID',
    writer  => 'setUID',
    default => sub {
        my $instance = shift;
        ("$instance" =~ /\((.*?)\)$/)[0];
    }
));

BinaryTree->meta->add_attribute('node' => (
    reader   => 'getNodeValue',
    writer   => 'setNodeValue',
    clearer  => 'clearNodeValue',
    init_arg => ':node'
));

BinaryTree->meta->add_attribute('parent' => (
    predicate => 'hasParent',
    reader    => 'getParent',
    writer    => 'setParent',
    clearer   => 'clearParent',
));

BinaryTree->meta->add_attribute('left' => (
    predicate => 'hasLeft',
    clearer   => 'clearLeft',
    reader    => 'getLeft',
    writer => {
        'setLeft' => sub {
            my ($self, $tree) = @_;
            confess "undef left" unless defined $tree;
                $tree->setParent($self) if defined $tree;
            $self->{'left'} = $tree;
            $self;
        }
   },
));

BinaryTree->meta->add_attribute('right' => (
    predicate => 'hasRight',
    clearer   => 'clearRight',
    reader    => 'getRight',
    writer => {
        'setRight' => sub {
            my ($self, $tree) = @_;
            confess "undef right" unless defined $tree;
                $tree->setParent($self) if defined $tree;
            $self->{'right'} = $tree;
            $self;
        }
    }
));

sub new {
    my $class = shift;
    $class->meta->new_object(':node' => shift);
}

sub removeLeft {
    my ($self) = @_;
    my $left = $self->getLeft();
    $left->clearParent;
    $self->clearLeft;
    return $left;
}

sub removeRight {
    my ($self) = @_;
    my $right = $self->getRight;
    $right->clearParent;
    $self->clearRight;
    return $right;
}

sub isLeaf {
        my ($self) = @_;
        return (!$self->hasLeft && !$self->hasRight);
}

sub isRoot {
        my ($self) = @_;
        return !$self->hasParent;
}

sub traverse {
        my ($self, $func) = @_;
    $func->($self);
    $self->getLeft->traverse($func)  if $self->hasLeft;
    $self->getRight->traverse($func) if $self->hasRight;
}

sub mirror {
    my ($self) = @_;
    # swap left for right
    if( $self->hasLeft && $self->hasRight) {
      my $left = $self->getLeft;
      my $right = $self->getRight;
      $self->setLeft($right);
      $self->setRight($left);
    } elsif( $self->hasLeft && !$self->hasRight){
      my $left = $self->getLeft;
      $self->clearLeft;
      $self->setRight($left);
    } elsif( !$self->hasLeft && $self->hasRight){
      my $right = $self->getRight;
      $self->clearRight;
      $self->setLeft($right);
    }

    # and recurse
    $self->getLeft->mirror  if $self->hasLeft;
    $self->getRight->mirror if $self->hasRight;
    $self;
}

sub size {
    my ($self) = @_;
    my $size = 1;
    $size += $self->getLeft->size  if $self->hasLeft;
    $size += $self->getRight->size if $self->hasRight;
    return $size;
}

sub height {
    my ($self) = @_;
    my ($left_height, $right_height) = (0, 0);
    $left_height = $self->getLeft->height()   if $self->hasLeft();
    $right_height = $self->getRight->height() if $self->hasRight();
    return 1 + (($left_height > $right_height) ? $left_height : $right_height);
}

1;
