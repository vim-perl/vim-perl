## This test ensures that sub DEMOLISHALL fires even if there is no sub DEMOLISH
## Currently fails because of a bad optimization in DESTROY
## Feb 12, 2009 -- Evan Carroll me@evancarroll.com
package Role::DemolishAll;
use Moose::Role;
our $ok = 0;

sub BUILD { $ok = 0 };
after 'DEMOLISHALL' => sub { $Role::DemolishAll::ok++ };

package DemolishAll::WithoutDemolish;
use Moose;
with 'Role::DemolishAll';

package DemolishAll::WithDemolish;
use Moose;
with 'Role::DemolishAll';
sub DEMOLISH {};


package main;
use Test::More;

my $m = DemolishAll::WithDemolish->new;
undef $m;
is ( $Role::DemolishAll::ok, 1, 'DemolishAll w/ explicit DEMOLISH sub' );

$m = DemolishAll::WithoutDemolish->new;
undef $m;
is ( $Role::DemolishAll::ok, 1, 'DemolishAll wo/ explicit DEMOLISH sub' );

done_testing;
