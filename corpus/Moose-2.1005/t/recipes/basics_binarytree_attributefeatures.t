#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
{

  package BinaryTree;
  use Moose;

  has 'node' => ( is => 'rw', isa => 'Any' );

  has 'parent' => (
      is        => 'rw',
      isa       => 'BinaryTree',
      predicate => 'has_parent',
      weak_ref  => 1,
  );

  has 'left' => (
      is        => 'rw',
      isa       => 'BinaryTree',
      predicate => 'has_left',
      lazy      => 1,
      default   => sub { BinaryTree->new( parent => $_[0] ) },
      trigger   => \&_set_parent_for_child
  );

  has 'right' => (
      is        => 'rw',
      isa       => 'BinaryTree',
      predicate => 'has_right',
      lazy      => 1,
      default   => sub { BinaryTree->new( parent => $_[0] ) },
      trigger   => \&_set_parent_for_child
  );

  sub _set_parent_for_child {
      my ( $self, $child ) = @_;

      confess "You cannot insert a tree which already has a parent"
          if $child->has_parent;

      $child->parent($self);
  }
}



# =begin testing
{
use Scalar::Util 'isweak';

my $root = BinaryTree->new(node => 'root');
isa_ok($root, 'BinaryTree');

is($root->node, 'root', '... got the right node value');

ok(!$root->has_left, '... no left node yet');
ok(!$root->has_right, '... no right node yet');

ok(!$root->has_parent, '... no parent for root node');

# make a left node

my $left = $root->left;
isa_ok($left, 'BinaryTree');

is($root->left, $left, '... got the same node (and it is $left)');
ok($root->has_left, '... we have a left node now');

ok($left->has_parent, '... lefts has a parent');
is($left->parent, $root, '... lefts parent is the root');

ok(isweak($left->{parent}), '... parent is a weakened ref');

ok(!$left->has_left, '... $left no left node yet');
ok(!$left->has_right, '... $left no right node yet');

is($left->node, undef, '... left has got no node value');

is(
    exception {
        $left->node('left');
    },
    undef,
    '... assign to lefts node'
);

is($left->node, 'left', '... left now has a node value');

# make a right node

ok(!$root->has_right, '... still no right node yet');

is($root->right->node, undef, '... right has got no node value');

ok($root->has_right, '... now we have a right node');

my $right = $root->right;
isa_ok($right, 'BinaryTree');

is(
    exception {
        $right->node('right');
    },
    undef,
    '... assign to rights node'
);

is($right->node, 'right', '... left now has a node value');

is($root->right, $right, '... got the same node (and it is $right)');
ok($root->has_right, '... we have a right node now');

ok($right->has_parent, '... rights has a parent');
is($right->parent, $root, '... rights parent is the root');

ok(isweak($right->{parent}), '... parent is a weakened ref');

# make a left node of the left node

my $left_left = $left->left;
isa_ok($left_left, 'BinaryTree');

ok($left_left->has_parent, '... left does have a parent');

is($left_left->parent, $left, '... got a parent node (and it is $left)');
ok($left->has_left, '... we have a left node now');
is($left->left, $left_left, '... got a left node (and it is $left_left)');

ok(isweak($left_left->{parent}), '... parent is a weakened ref');

# make a right node of the left node

my $left_right = BinaryTree->new;
isa_ok($left_right, 'BinaryTree');

is(
    exception {
        $left->right($left_right);
    },
    undef,
    '... assign to rights node'
);

ok($left_right->has_parent, '... left does have a parent');

is($left_right->parent, $left, '... got a parent node (and it is $left)');
ok($left->has_right, '... we have a left node now');
is($left->right, $left_right, '... got a left node (and it is $left_left)');

ok(isweak($left_right->{parent}), '... parent is a weakened ref');

# and check the error

isnt(
    exception {
        $left_right->right($left_left);
    },
    undef,
    '... cannot assign a node which already has a parent'
);
}




1;
