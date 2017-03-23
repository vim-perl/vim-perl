#!/usr/bin/perl

use lib "t/lib";
use strict;
use warnings;

use Test::More;

BEGIN {
    package MyExporterRole;

    use Moose ();
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        also      => 'Moose',
    );

    sub init_meta {
        my ($class,%args) = @_;

        my $meta = Moose->init_meta( %args );

        Moose::Util::MetaRole::apply_metaroles(
            for             => $meta,
            class_metaroles => {
                class           => ['MyMetaRole'],
            },
        );

        return $meta;
    }

    $INC{'MyExporterRole.pm'} = __FILE__;
}

{
    package MyMetaRole;
    use Moose::Role;

    sub some_meta_class_method {
        return "HEY"
    }
}

{
    package MyTrait;
    use Moose::Role;

    sub some_meta_class_method_defined_by_trait {
        return "HO"
    }

    {
        package Moose::Meta::Class::Custom::Trait::MyClassTrait;
        use strict;
        use warnings;
        sub register_implementation { return 'MyTrait' }
    }
}

{
    package MyClass;
    use MyExporterRole -traits => 'MyClassTrait';
}



my $my_class = MyClass->new;

isa_ok($my_class,'MyClass');

my $meta = $my_class->meta();
# Check if MyMetaRole has been applied
ok($meta->can('some_meta_class_method'),'Meta class has some_meta_class_method');
# Check if MyTrait has been applied
ok($meta->can('some_meta_class_method_defined_by_trait'),'Meta class has some_meta_class_method_defined_by_trait');

done_testing;
