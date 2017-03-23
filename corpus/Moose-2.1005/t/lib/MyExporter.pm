

package MyExporter;
use Moose::Exporter;
use Test::More;

Moose::Exporter->setup_import_methods(
    with_meta => [qw(with_prototype)],
    as_is     => [qw(as_is_prototype)],
);

sub with_prototype (&) {
    my ($class, $code) = @_;
    isa_ok($code, 'CODE', 'with_prototype received a coderef');
    $code->();
}

sub as_is_prototype (&) {
    my ($code) = @_;
    isa_ok($code, 'CODE', 'as_is_prototype received a coderef');
    $code->();
}

1;
