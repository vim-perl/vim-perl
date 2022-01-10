package # hide from PAUSE
    Moose::Conflicts;

use strict;
use warnings;

use Dist::CheckConflicts
    -dist      => 'Moose',
    -conflicts => {
        'Catalyst' => '5.80028',
        'Devel::REPL' => '1.003008',
        'Fey' => '0.36',
        'Fey::ORM' => '0.42',
        'File::ChangeNotify' => '0.15',
        'KiokuDB' => '0.51',
        'Markdent' => '0.16',
        'Mason' => '2.18',
        'MooseX::ABC' => '0.05',
        'MooseX::Aliases' => '0.08',
        'MooseX::AlwaysCoerce' => '0.13',
        'MooseX::App' => '1.18',
        'MooseX::Attribute::Deflator' => '2.1.7',
        'MooseX::Attribute::Dependent' => '1.1.0',
        'MooseX::Attribute::Prototype' => '0.10',
        'MooseX::AttributeHelpers' => '0.22',
        'MooseX::AttributeIndexes' => '1.0.0',
        'MooseX::AttributeInflate' => '0.02',
        'MooseX::CascadeClearing' => '0.03',
        'MooseX::ClassAttribute' => '0.26',
        'MooseX::Constructor::AllErrors' => '0.012',
        'MooseX::FollowPBP' => '0.02',
        'MooseX::HasDefaults' => '0.02',
        'MooseX::InstanceTracking' => '0.04',
        'MooseX::LazyRequire' => '0.06',
        'MooseX::Meta::Attribute::Index' => '0.04',
        'MooseX::Meta::Attribute::Lvalue' => '0.05',
        'MooseX::MethodAttributes' => '0.22',
        'MooseX::NonMoose' => '0.17',
        'MooseX::POE' => '0.214',
        'MooseX::Params::Validate' => '0.05',
        'MooseX::PrivateSetters' => '0.03',
        'MooseX::Role::Cmd' => '0.06',
        'MooseX::Role::Parameterized' => '0.23',
        'MooseX::Role::WithOverloading' => '0.07',
        'MooseX::Scaffold' => '0.05',
        'MooseX::SemiAffordanceAccessor' => '0.05',
        'MooseX::SetOnce' => '0.100473',
        'MooseX::Singleton' => '0.25',
        'MooseX::SlurpyConstructor' => '1.1',
        'MooseX::StrictConstructor' => '0.12',
        'MooseX::Types' => '0.19',
        'MooseX::Types::Parameterizable' => '0.05',
        'MooseX::Types::Signal' => '1.101930',
        'MooseX::UndefTolerant' => '0.11',
        'PRANG' => '0.14',
        'Pod::Elemental' => '0.093280',
        'Reaction' => '0.002003',
        'Test::Able' => '0.10',
        'namespace::autoclean' => '0.08',
    },

;

1;

# ABSTRACT: Provide information on conflicts for Moose

__END__

=pod

=head1 NAME

Moose::Conflicts - Provide information on conflicts for Moose

=head1 VERSION

version 2.1005

=head1 AUTHOR

Moose is maintained by the Moose Cabal, along with the help of many contributors. See L<Moose/CABAL> and L<Moose/CONTRIBUTORS> for details.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
