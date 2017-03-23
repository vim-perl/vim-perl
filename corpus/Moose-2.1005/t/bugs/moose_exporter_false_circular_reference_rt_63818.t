#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

# OKSet1
{

    package TESTING::MooseExporter::Rt63818::OKSet1::ModuleA;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
        ]
    );
}

# OKSet2
{

    package TESTING::MooseExporter::Rt63818::OKSet2::ModuleA;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
        ]
    );

    package TESTING::MooseExporter::Rt63818::OKSet2::ModuleB;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
        ]
    );
}

# OKSet3
{

    package TESTING::MooseExporter::Rt63818::OKSet3::ModuleA;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
        ]
    );

    package TESTING::MooseExporter::Rt63818::OKSet3::ModuleB;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
            'TESTING::MooseExporter::Rt63818::OKSet3::ModuleA',
        ]
    );
}

# OKSet4
{

    package TESTING::MooseExporter::Rt63818::OKSet4::ModuleA;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
        ]
    );

    package TESTING::MooseExporter::Rt63818::OKSet4::ModuleB;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
            'TESTING::MooseExporter::Rt63818::OKSet4::ModuleA',
        ]
    );

    package TESTING::MooseExporter::Rt63818::OKSet4::ModuleC;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
            'TESTING::MooseExporter::Rt63818::OKSet4::ModuleA',
            'TESTING::MooseExporter::Rt63818::OKSet4::ModuleB',
        ]
    );
}

# OKSet5
{

    package TESTING::MooseExporter::Rt63818::OKSet5::ModuleA;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
        ]
    );

    package TESTING::MooseExporter::Rt63818::OKSet5::ModuleB;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
            'TESTING::MooseExporter::Rt63818::OKSet5::ModuleA',
        ]
    );

    package TESTING::MooseExporter::Rt63818::OKSet5::ModuleC;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
            'TESTING::MooseExporter::Rt63818::OKSet5::ModuleA',
            'TESTING::MooseExporter::Rt63818::OKSet5::ModuleB',
        ]
    );

    package TESTING::MooseExporter::Rt63818::OKSet5::ModuleD;
    use Moose ();
    Moose::Exporter->setup_import_methods(
        also => [
            'Moose',
            'TESTING::MooseExporter::Rt63818::OKSet5::ModuleA',
            'TESTING::MooseExporter::Rt63818::OKSet5::ModuleC',
        ]
    );
}

# NotOKSet1
{

    package TESTING::MooseExporter::Rt63818::NotOKSet1::ModuleA;
    use Moose ();
    ::like(
        ::exception { Moose::Exporter->setup_import_methods(
                also => [
                    'Moose',
                    'TESTING::MooseExporter::Rt63818::NotOKSet1::ModuleA',
                ]
            )
            },
        qr/\QCircular reference in 'also' parameter to Moose::Exporter between TESTING::MooseExporter::Rt63818::NotOKSet1::ModuleA and TESTING::MooseExporter::Rt63818::NotOKSet1::ModuleA/,
        'a single-hop circular reference in also dies with an error'
    );
}

# Alas, I've not figured out how to craft a test which shows that we get the
# same error for multi-hop circularity... instead I get tests that die because
# one of the circularly-referenced things was not loaded.

done_testing;
