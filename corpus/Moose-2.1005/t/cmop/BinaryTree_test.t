use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use Test::More;
use Test::Fatal;

use Class::Load qw( is_class_loaded load_class );

use lib catdir($FindBin::Bin, 'lib');

## ----------------------------------------------------------------------------
## These are all tests which are derived from the Tree::Binary test suite
## ----------------------------------------------------------------------------

ok(!is_class_loaded('BinaryTree'), '... the binary tree class is not loaded');

is( exception {
    load_class('BinaryTree');
}, undef, '... loaded the BinaryTree class without dying' );

ok(is_class_loaded('BinaryTree'), '... the binary tree class is now loaded');

## ----------------------------------------------------------------------------
## t/10_Tree_Binary_test.t

can_ok("BinaryTree", 'new');
can_ok("BinaryTree", 'setLeft');
can_ok("BinaryTree", 'setRight');

my $btree = BinaryTree->new("/")
                        ->setLeft(
                            BinaryTree->new("+")
                                        ->setLeft(
                                            BinaryTree->new("2")
                                        )
                                        ->setRight(
                                            BinaryTree->new("2")
                                        )
                        )
                        ->setRight(
                            BinaryTree->new("*")
                                        ->setLeft(
                                            BinaryTree->new("4")
                                        )
                                        ->setRight(
                                            BinaryTree->new("5")
                                        )
                        );
isa_ok($btree, 'BinaryTree');

## informational methods

can_ok($btree, 'isRoot');
ok($btree->isRoot(), '... this is the root');

can_ok($btree, 'isLeaf');
ok(!$btree->isLeaf(), '... this is not a leaf node');
ok($btree->getLeft()->getLeft()->isLeaf(), '... this is a leaf node');

can_ok($btree, 'hasLeft');
ok($btree->hasLeft(), '... this has a left node');

can_ok($btree, 'hasRight');
ok($btree->hasRight(), '... this has a right node');

## accessors

can_ok($btree, 'getUID');

{
    my $UID = $btree->getUID();
    is(("$btree" =~ /\((.*?)\)$/)[0], $UID, '... our UID is derived from the stringified object');
}

can_ok($btree, 'getNodeValue');
is($btree->getNodeValue(), '/', '... got what we expected');

{
    can_ok($btree, 'getLeft');
    my $left = $btree->getLeft();

    isa_ok($left, 'BinaryTree');

    is($left->getNodeValue(), '+', '... got what we expected');

    can_ok($left, 'getParent');

    my $parent = $left->getParent();
    isa_ok($parent, 'BinaryTree');

    is($parent, $btree, '.. got what we expected');
}

{
    can_ok($btree, 'getRight');
    my $right = $btree->getRight();

    isa_ok($right, 'BinaryTree');

    is($right->getNodeValue(), '*', '... got what we expected');

    can_ok($right, 'getParent');

    my $parent = $right->getParent();
    isa_ok($parent, 'BinaryTree');

    is($parent, $btree, '.. got what we expected');
}

## mutators

can_ok($btree, 'setUID');
$btree->setUID("Our UID for this tree");

is($btree->getUID(), 'Our UID for this tree', '... our UID is not what we expected');

can_ok($btree, 'setNodeValue');
$btree->setNodeValue('*');

is($btree->getNodeValue(), '*', '... got what we expected');


{
    can_ok($btree, 'removeLeft');
    my $left = $btree->removeLeft();
    isa_ok($left, 'BinaryTree');

    ok(!$btree->hasLeft(), '... we dont have a left node anymore');
    ok(!$btree->isLeaf(), '... and we are not a leaf node');

    $btree->setLeft($left);

    ok($btree->hasLeft(), '... we have our left node again');
    is($btree->getLeft(), $left, '... and it is what we told it to be');
}

{
    # remove left leaf
    my $left_leaf = $btree->getLeft()->removeLeft();
    isa_ok($left_leaf, 'BinaryTree');

    ok($left_leaf->isLeaf(), '... our left leaf is a leaf');

    ok(!$btree->getLeft()->hasLeft(), '... we dont have a left leaf node anymore');

    $btree->getLeft()->setLeft($left_leaf);

    ok($btree->getLeft()->hasLeft(), '... we have our left leaf node again');
    is($btree->getLeft()->getLeft(), $left_leaf, '... and it is what we told it to be');
}

{
    can_ok($btree, 'removeRight');
    my $right = $btree->removeRight();
    isa_ok($right, 'BinaryTree');

    ok(!$btree->hasRight(), '... we dont have a right node anymore');
    ok(!$btree->isLeaf(), '... and we are not a leaf node');

    $btree->setRight($right);

    ok($btree->hasRight(), '... we have our right node again');
    is($btree->getRight(), $right, '... and it is what we told it to be')
}

{
    # remove right leaf
    my $right_leaf = $btree->getRight()->removeRight();
    isa_ok($right_leaf, 'BinaryTree');

    ok($right_leaf->isLeaf(), '... our right leaf is a leaf');

    ok(!$btree->getRight()->hasRight(), '... we dont have a right leaf node anymore');

    $btree->getRight()->setRight($right_leaf);

    ok($btree->getRight()->hasRight(), '... we have our right leaf node again');
    is($btree->getRight()->getRight(), $right_leaf, '... and it is what we told it to be');
}

# some of the recursive informational methods

{

    my $btree = BinaryTree->new("o")
                            ->setLeft(
                                BinaryTree->new("o")
                                    ->setLeft(
                                        BinaryTree->new("o")
                                    )
                                    ->setRight(
                                        BinaryTree->new("o")
                                            ->setLeft(
                                                BinaryTree->new("o")
                                                    ->setLeft(
                                                        BinaryTree->new("o")
                                                            ->setRight(BinaryTree->new("o"))
                                                    )
                                            )
                                    )
                            )
                            ->setRight(
                                BinaryTree->new("o")
                                            ->setLeft(
                                                BinaryTree->new("o")
                                                    ->setRight(
                                                        BinaryTree->new("o")
                                                            ->setLeft(
                                                                BinaryTree->new("o")
                                                            )
                                                            ->setRight(
                                                                BinaryTree->new("o")
                                                            )
                                                    )
                                            )
                                            ->setRight(
                                                BinaryTree->new("o")
                                                    ->setRight(BinaryTree->new("o"))
                                            )
                            );
    isa_ok($btree, 'BinaryTree');

    can_ok($btree, 'size');
    cmp_ok($btree->size(), '==', 14, '... we have 14 nodes in the tree');

    can_ok($btree, 'height');
    cmp_ok($btree->height(), '==', 6, '... the tree is 6 nodes tall');

}

## ----------------------------------------------------------------------------
## t/13_Tree_Binary_mirror_test.t

sub inOrderTraverse {
    my $tree = shift;
    my @results;
    my $_inOrderTraverse = sub {
        my ($tree, $traversal_function) = @_;
        $traversal_function->($tree->getLeft(), $traversal_function) if $tree->hasLeft();
        push @results => $tree->getNodeValue();
        $traversal_function->($tree->getRight(), $traversal_function) if $tree->hasRight();
    };
    $_inOrderTraverse->($tree, $_inOrderTraverse);
    @results;
}

# test it on a simple well balanaced tree
{
    my $btree = BinaryTree->new(4)
                    ->setLeft(
                        BinaryTree->new(2)
                            ->setLeft(
                                BinaryTree->new(1)
                                )
                            ->setRight(
                                BinaryTree->new(3)
                                )
                        )
                    ->setRight(
                        BinaryTree->new(6)
                            ->setLeft(
                                BinaryTree->new(5)
                                )
                            ->setRight(
                                BinaryTree->new(7)
                                )
                        );
    isa_ok($btree, 'BinaryTree');

    is_deeply(
        [ inOrderTraverse($btree) ],
        [ 1 .. 7 ],
        '... check that our tree starts out correctly');

    can_ok($btree, 'mirror');
    $btree->mirror();

    is_deeply(
        [ inOrderTraverse($btree) ],
        [ reverse(1 .. 7) ],
        '... check that our tree ends up correctly');
}

# test is on a more chaotic tree
{
    my $btree = BinaryTree->new(4)
                    ->setLeft(
                        BinaryTree->new(20)
                            ->setLeft(
                                BinaryTree->new(1)
                                        ->setRight(
                                            BinaryTree->new(10)
                                                ->setLeft(
                                                    BinaryTree->new(5)
                                                )
                                        )
                                )
                            ->setRight(
                                BinaryTree->new(3)
                                )
                        )
                    ->setRight(
                        BinaryTree->new(6)
                            ->setLeft(
                                BinaryTree->new(5)
                                    ->setRight(
                                        BinaryTree->new(7)
                                            ->setLeft(
                                                BinaryTree->new(90)
                                            )
                                            ->setRight(
                                                BinaryTree->new(91)
                                            )
                                        )
                                )
                        );
    isa_ok($btree, 'BinaryTree');

    my @results = inOrderTraverse($btree);

    $btree->mirror();

    is_deeply(
        [ inOrderTraverse($btree) ],
        [ reverse(@results) ],
        '... this should be the reverse of the original');
}

done_testing;
