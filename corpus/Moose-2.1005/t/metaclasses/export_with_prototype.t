use lib "t/lib";
package MyExporter::User;
use MyExporter;

use Test::More;
use Test::Fatal;

is( exception {
    with_prototype {
        my $caller = caller(0);
        is($caller, 'MyExporter', "With_caller prototype code gets called from MyMooseX");
    };
}, undef, "check function with prototype" );

is( exception {
    as_is_prototype {
        my $caller = caller(0);
        is($caller, 'MyExporter', "As-is prototype code gets called from MyMooseX");
    };
}, undef, "check function with prototype" );

done_testing;
