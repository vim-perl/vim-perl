use Test::More 0.94;
use Test::CheckDeps 0.004;

check_dependencies('classic');

if (0) {
    BAIL_OUT("Missing dependencies") if !Test::More->builder->is_passing;
}

done_testing;

