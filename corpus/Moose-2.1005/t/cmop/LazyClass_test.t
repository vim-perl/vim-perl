use strict;
use warnings;

use Test::More;
use File::Spec;

use Class::MOP;

BEGIN {
    require_ok(File::Spec->catfile('examples', 'LazyClass.pod'));
}

{
    package BinaryTree;

    use metaclass (
        'attribute_metaclass' => 'LazyClass::Attribute',
        'instance_metaclass'  => 'LazyClass::Instance',
    );

    BinaryTree->meta->add_attribute('node' => (
        accessor => 'node',
        init_arg => 'node'
    ));

    BinaryTree->meta->add_attribute('left' => (
        reader  => 'left',
        default => sub { BinaryTree->new() }
    ));

    BinaryTree->meta->add_attribute('right' => (
        reader  => 'right',
        default => sub { BinaryTree->new() }
    ));

    sub new {
        my $class = shift;
        bless $class->meta->new_object(@_) => $class;
    }
}

my $root = BinaryTree->new('node' => 0);
isa_ok($root, 'BinaryTree');

ok(exists($root->{'node'}), '... node attribute has been initialized yet');
ok(!exists($root->{'left'}), '... left attribute has not been initialized yet');
ok(!exists($root->{'right'}), '... right attribute has not been initialized yet');

isa_ok($root->left, 'BinaryTree');
isa_ok($root->right, 'BinaryTree');

ok(exists($root->{'left'}), '... left attribute has now been initialized');
ok(exists($root->{'right'}), '... right attribute has now been initialized');

ok(!exists($root->left->{'node'}), '... node attribute has not been initialized yet');
ok(!exists($root->left->{'left'}), '... left attribute has not been initialized yet');
ok(!exists($root->left->{'right'}), '... right attribute has not been initialized yet');

ok(!exists($root->right->{'node'}), '... node attribute has not been initialized yet');
ok(!exists($root->right->{'left'}), '... left attribute has not been initialized yet');
ok(!exists($root->right->{'right'}), '... right attribute has not been initialized yet');

is($root->left->node(), undef, '... the left node is uninitialized');

ok(exists($root->left->{'node'}), '... node attribute has now been initialized');

$root->left->node(1);
is($root->left->node(), 1, '... the left node == 1');

ok(!exists($root->left->{'left'}), '... left attribute still has not been initialized yet');
ok(!exists($root->left->{'right'}), '... right attribute still has not been initialized yet');

is($root->right->node(), undef, '... the right node is uninitialized');

ok(exists($root->right->{'node'}), '... node attribute has now been initialized');

$root->right->node(2);
is($root->right->node(), 2, '... the right node == 1');

ok(!exists($root->right->{'left'}), '... left attribute still has not been initialized yet');
ok(!exists($root->right->{'right'}), '... right attribute still has not been initialized yet');

done_testing;
