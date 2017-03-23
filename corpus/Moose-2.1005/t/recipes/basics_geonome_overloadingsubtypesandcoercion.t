#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


{
    package Human;

    use Moose;
    use Moose::Util::TypeConstraints;

    subtype 'Sex'
        => as 'Str'
        => where { $_ =~ m{^[mf]$}s };

    has 'sex'    => ( is => 'ro', isa => 'Sex', required => 1 );

    has 'mother' => ( is => 'ro', isa => 'Human' );
    has 'father' => ( is => 'ro', isa => 'Human' );

    use overload '+' => \&_overload_add, fallback => 1;

    sub _overload_add {
        my ( $one, $two ) = @_;

        die('Only male and female humans may create children')
            if ( $one->sex() eq $two->sex() );

        my ( $mother, $father )
            = ( $one->sex eq 'f' ? ( $one, $two ) : ( $two, $one ) );

        my $sex = 'f';
        $sex = 'm' if ( rand() >= 0.5 );

        return Human->new(
            sex       => $sex,
            eye_color => ( $one->eye_color() + $two->eye_color() ),
            mother    => $mother,
            father    => $father,
        );
    }

    use List::MoreUtils qw( zip );

    coerce 'Human::EyeColor'
        => from 'ArrayRef'
        => via { my @genes = qw( bey2_1 bey2_2 gey_1 gey_2 );
                 return Human::EyeColor->new( zip( @genes, @{$_} ) ); };

    has 'eye_color' => (
        is       => 'ro',
        isa      => 'Human::EyeColor',
        coerce   => 1,
        required => 1,
    );

}

{
    package Human::Gene::bey2;

    use Moose;
    use Moose::Util::TypeConstraints;

    type 'bey2_color' => where { $_ =~ m{^(?:brown|blue)$} };

    has 'color' => ( is => 'ro', isa => 'bey2_color' );
}

{
    package Human::Gene::gey;

    use Moose;
    use Moose::Util::TypeConstraints;

    type 'gey_color' => where { $_ =~ m{^(?:green|blue)$} };

    has 'color' => ( is => 'ro', isa => 'gey_color' );
}

{
    package Human::EyeColor;

    use Moose;
    use Moose::Util::TypeConstraints;

    coerce 'Human::Gene::bey2'
        => from 'Str'
            => via { Human::Gene::bey2->new( color => $_ ) };

    coerce 'Human::Gene::gey'
        => from 'Str'
            => via { Human::Gene::gey->new( color => $_ ) };

    has [qw( bey2_1 bey2_2 )] =>
        ( is => 'ro', isa => 'Human::Gene::bey2', coerce => 1 );

    has [qw( gey_1 gey_2 )] =>
        ( is => 'ro', isa => 'Human::Gene::gey', coerce => 1 );

    sub color {
        my ($self) = @_;

        return 'brown'
            if ( $self->bey2_1->color() eq 'brown'
            or $self->bey2_2->color() eq 'brown' );

        return 'green'
            if ( $self->gey_1->color() eq 'green'
            or $self->gey_2->color() eq 'green' );

        return 'blue';
    }

    use overload '""' => \&color, fallback => 1;

    use overload '+' => \&_overload_add, fallback => 1;

    sub _overload_add {
        my ( $one, $two ) = @_;

        my $one_bey2 = 'bey2_' . _rand2();
        my $two_bey2 = 'bey2_' . _rand2();

        my $one_gey = 'gey_' . _rand2();
        my $two_gey = 'gey_' . _rand2();

        return Human::EyeColor->new(
            bey2_1 => $one->$one_bey2->color(),
            bey2_2 => $two->$two_bey2->color(),
            gey_1  => $one->$one_gey->color(),
            gey_2  => $two->$two_gey->color(),
        );
    }

    sub _rand2 {
        return 1 + int( rand(2) );
    }
}

my $gene_color_sets = [
    [ qw( blue blue blue blue )     => 'blue' ],
    [ qw( blue blue green blue )    => 'green' ],
    [ qw( blue blue blue green )    => 'green' ],
    [ qw( blue blue green green )   => 'green' ],
    [ qw( brown blue blue blue )    => 'brown' ],
    [ qw( brown brown green green ) => 'brown' ],
    [ qw( blue brown green blue )   => 'brown' ],
];

foreach my $set (@$gene_color_sets) {
    my $expected_color = pop(@$set);

    my $person = Human->new(
        sex       => 'f',
        eye_color => $set,
    );

    is(
        $person->eye_color(),
        $expected_color,
        'gene combination '
            . join( ',', @$set )
            . ' produces '
            . $expected_color
            . ' eye color',
    );
}

my $parent_sets = [
    [
        [qw( blue blue blue blue )],
        [qw( blue blue blue blue )] => 'blue'
    ],
    [
        [qw( blue blue blue blue )],
        [qw( brown brown green blue )] => 'brown'
    ],
    [
        [qw( blue blue green green )],
        [qw( blue blue green green )] => 'green'
    ],
];

foreach my $set (@$parent_sets) {
    my $expected_color = pop(@$set);

    my $mother         = Human->new(
        sex       => 'f',
        eye_color => shift(@$set),
    );

    my $father = Human->new(
        sex       => 'm',
        eye_color => shift(@$set),
    );

    my $child = $mother + $father;

    is(
        $child->eye_color(),
        $expected_color,
        'mother '
            . $mother->eye_color()
            . ' + father '
            . $father->eye_color()
            . ' = child '
            . $expected_color,
    );
}

# Hmm, not sure how to test for random selection of genes since
# I could theoretically run an infinite number of iterations and
# never find proof that a child has inherited a particular gene.

# AUTHOR: Aran Clary Deltac <bluefeet@cpan.org>

done_testing;
