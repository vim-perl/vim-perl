#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package ApplicationMetaRole;
    use Moose::Role;
    use Moose::Util::MetaRole;

    after apply => sub {
        my ($self, $role_source, $role_dest, $args) = @_;
        Moose::Util::MetaRole::apply_metaroles
        (
            for            => $role_dest,
            role_metaroles =>
            {
                application_to_role => ['ApplicationMetaRole'],
            }
        );
    };
}
{
    package MyMetaRole;
    use Moose::Role;
    use Moose::Util::MetaRole;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(also => q<Moose::Role>);

    sub init_meta {
        my ($class, %opts) = @_;
        Moose::Role->init_meta(%opts);
        Moose::Util::MetaRole::apply_metaroles
        (
            for            => $opts{for_class},
            role_metaroles =>
            {
                application_to_role => ['ApplicationMetaRole'],
            }
        );
        return $opts{for_class}->meta();
    };
}

{
    package MyRole;
    use Moose::Role;

    MyMetaRole->import;

    use Moose::Util::TypeConstraints;

    has schema => (
        is     => 'ro',
        coerce => 1,
    );
}

{
    package MyTargetRole;
    use Moose::Role;
    ::is(::exception { with "MyRole" }, undef,
         "apply a meta role to a role, which is then applied to yet another role");
}

done_testing;
