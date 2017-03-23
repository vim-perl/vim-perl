use strict;
use warnings;
use Test::More;
use Class::MOP;

my $Point = Class::MOP::Class->create('Point' => (
    version    => '0.01',
    attributes => [
        Class::MOP::Attribute->new('x' => (
            reader   => 'x',
            init_arg => 'x'
        )),
        Class::MOP::Attribute->new('y' => (
            accessor => 'y',
            init_arg => 'y'
        )),
    ],
    methods => {
        'new' => sub {
            my $class = shift;
            my $instance = $class->meta->new_object(@_);
            bless $instance => $class;
        },
        'clear' => sub {
            my $self = shift;
            $self->{'x'} = 0;
            $self->{'y'} = 0;
        }
    }
));

is($Point->get_attribute('x')->insertion_order, 0, 'Insertion order of Attribute "x"');
is($Point->get_attribute('y')->insertion_order, 1, 'Insertion order of Attribute "y"');

done_testing;
