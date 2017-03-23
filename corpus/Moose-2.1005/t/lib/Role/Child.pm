package Role::Child;
use Moose::Role;

with 'Role::Parent' => { -alias => { meth1 => 'aliased_meth1', } };

sub meth1 { }

1;
