package MyRole;

use Moose::Role;

sub foo { return (caller(0))[3] }

no Moose::Role;

package MyClass1; use Moose; with 'MyRole'; no Moose;
package MyClass2; use Moose; with 'MyRole'; no Moose;

package main;

use Test::More;

{
  local $TODO = 'Role composition does not clone methods yet';
  is(MyClass1->foo, 'MyClass1::foo',
    'method from role has correct name in caller()');
  is(MyClass2->foo, 'MyClass2::foo',
    'method from role has correct name in caller()');
}

isnt(MyClass1->foo, "MyClass2::foo", "role method is not confused with other class" );
isnt(MyClass2->foo, "MyClass1::foo", "role method is not confused with other class" );

done_testing;
