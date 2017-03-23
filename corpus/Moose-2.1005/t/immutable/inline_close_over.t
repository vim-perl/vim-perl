#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Class::Load 'load_class';
use Test::Requires 'Data::Visitor';
use Test::Requires 'PadWalker';
use Try::Tiny;
my $can_partialdump = try {
    load_class('Devel::PartialDump', { -version => 0.14 }); 1;
};

{
    package Test::Visitor;
    use Moose;
    use Moose::Util::TypeConstraints;
    extends 'Data::Visitor';

    has closed_over => (
        traits  => ['Array'],
        isa     => 'ArrayRef',
        default => sub { [] },
        handles => {
            add_closed_over => 'push',
            closed_over     => 'elements',
            pass            => 'is_empty',
        },
    );

    before visit_code => sub {
        my $self = shift;
        my ($code) = @_;
        my $closed_over = PadWalker::closed_over($code);
        $self->visit_ref($closed_over);
    };

    after visit => sub {
        my $self = shift;
        my ($thing) = @_;

        $self->add_closed_over($thing)
            unless $self->_is_okay_to_close_over($thing);
    };

    sub _is_okay_to_close_over {
        my $self = shift;
        my ($thing) = @_;

        match_on_type $thing => (
            'RegexpRef'  => sub { 1 },
            'Object'     => sub { 0 },
            'GlobRef'    => sub { 0 },
            'FileHandle' => sub { 0 },
            'Any'        => sub { 1 },
        );
    }
}

sub close_over_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($package, $method) = @_;
    my $visitor = Test::Visitor->new;
    my $code = $package->meta->find_method_by_name($method)->body;
    $visitor->visit($code);
    if ($visitor->pass) {
        pass("${package}::${method} didn't close over anything complicated");
    }
    else {
        fail("${package}::${method} closed over some stuff:");
        my @closed_over = $visitor->closed_over;
        for my $i (1..10) {
            last unless @closed_over;
            my $closed_over = shift @closed_over;
            if ($can_partialdump) {
                $closed_over = Devel::PartialDump->new->dump($closed_over);
            }
            diag($closed_over);
        }
        diag("... and " . scalar(@closed_over) . " more")
            if @closed_over;
    }
}

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;

    has foo => (
        is  => 'ro',
        isa => 'Str',
    );

    has bar => (
        is      => 'ro',
        isa     => 'Int',
        default => 1,
    );

    has baz => (
        is      => 'rw',
        isa     => 'ArrayRef[Num]',
        default => sub { [ 1.2 ] },
        trigger => sub { warn "blah" },
    );

    subtype 'Thing',
         as 'Int',
         where { $_ < 5 },
         message { "must be less than 5" };
    has quux => (
        is        => 'rw',
        isa       => 'Thing',
        predicate => 'has_quux',
        clearer   => 'clear_quux',
    );

    __PACKAGE__->meta->make_immutable;
}

close_over_ok('Foo', $_) for qw(new foo bar baz quux has_quux clear_quux);

{
    package Foo::Sub;
    use Moose;
    extends 'Foo';

    around foo => sub {
        my $orig = shift;
        my $self = shift;
        $self->$orig(@_);
    };

    after bar => sub { };
    before baz => sub { };
    override quux => sub { super };

    sub blah { inner }

    __PACKAGE__->meta->make_immutable;
}

close_over_ok('Foo::Sub', $_) for qw(new foo bar baz quux blah);

{
    package Foo::Sub::Sub;
    use Moose;
    extends 'Foo::Sub';

    augment blah => { inner };

    __PACKAGE__->meta->make_immutable;
}

close_over_ok('Foo::Sub::Sub', $_) for qw(new blah);

{
    my %handles = (
        Array   => {
            count                 => 'count',
            elements              => 'elements',
            is_empty              => 'is_empty',
            push                  => 'push',
            push_curried          => [ push => 42, 84 ],
            unshift               => 'unshift',
            unshift_curried       => [ unshift => 42, 84 ],
            pop                   => 'pop',
            shift                 => 'shift',
            get                   => 'get',
            get_curried           => [ get => 1 ],
            set                   => 'set',
            set_curried_1         => [ set => 1 ],
            set_curried_2         => [ set => ( 1, 98 ) ],
            accessor              => 'accessor',
            accessor_curried_1    => [ accessor => 1 ],
            accessor_curried_2    => [ accessor => ( 1, 90 ) ],
            clear                 => 'clear',
            delete                => 'delete',
            delete_curried        => [ delete => 1 ],
            insert                => 'insert',
            insert_curried        => [ insert => ( 1, 101 ) ],
            splice                => 'splice',
            splice_curried_1      => [ splice => 1 ],
            splice_curried_2      => [ splice => 1, 2 ],
            splice_curried_all    => [ splice => 1, 2, ( 3, 4, 5 ) ],
            sort                  => 'sort',
            sort_curried          => [ sort => ( sub { $_[1] <=> $_[0] } ) ],
            sort_in_place         => 'sort_in_place',
            sort_in_place_curried =>
                [ sort_in_place => ( sub { $_[1] <=> $_[0] } ) ],
            map                   => 'map',
            map_curried           => [ map => ( sub { $_ + 1 } ) ],
            grep                  => 'grep',
            grep_curried          => [ grep => ( sub { $_ < 5 } ) ],
            first                 => 'first',
            first_curried         => [ first => ( sub { $_ % 2 } ) ],
            join                  => 'join',
            join_curried          => [ join => '-' ],
            shuffle               => 'shuffle',
            uniq                  => 'uniq',
            reduce                => 'reduce',
            reduce_curried        => [ reduce => ( sub { $_[0] * $_[1] } ) ],
            natatime              => 'natatime',
            natatime_curried      => [ natatime => 2 ],
        },
        Hash    => {
            option_accessor  => 'accessor',
            quantity         => [ accessor => 'quantity' ],
            clear_options    => 'clear',
            num_options      => 'count',
            delete_option    => 'delete',
            is_defined       => 'defined',
            options_elements => 'elements',
            has_option       => 'exists',
            get_option       => 'get',
            has_no_options   => 'is_empty',
            keys             => 'keys',
            values           => 'values',
            key_value        => 'kv',
            set_option       => 'set',
        },
        Counter => {
            inc_counter    => 'inc',
            inc_counter_2  => [ inc => 2 ],
            dec_counter    => 'dec',
            dec_counter_2  => [ dec => 2 ],
            reset_counter  => 'reset',
            set_counter    => 'set',
            set_counter_42 => [ set => 42 ],
        },
        Number  => {
            abs         => 'abs',
            add         => 'add',
            inc         => [ add => 1 ],
            div         => 'div',
            cut_in_half => [ div => 2 ],
            mod         => 'mod',
            odd         => [ mod => 2 ],
            mul         => 'mul',
            set         => 'set',
            sub         => 'sub',
            dec         => [ sub => 1 ],
        },
        Bool    => {
            illuminate  => 'set',
            darken      => 'unset',
            flip_switch => 'toggle',
            is_dark     => 'not',
        },
        String  => {
            inc              => 'inc',
            append           => 'append',
            append_curried   => [ append => '!' ],
            prepend          => 'prepend',
            prepend_curried  => [ prepend => '-' ],
            replace          => 'replace',
            replace_curried  => [ replace => qr/(.)$/, sub { uc $1 } ],
            chop             => 'chop',
            chomp            => 'chomp',
            clear            => 'clear',
            match            => 'match',
            match_curried    => [ match  => qr/\D/ ],
            length           => 'length',
            substr           => 'substr',
            substr_curried_1 => [ substr => (1) ],
            substr_curried_2 => [ substr => ( 1, 3 ) ],
            substr_curried_3 => [ substr => ( 1, 3, 'ong' ) ],
        },
        Code    => {
            execute        => 'execute',
            execute_method => 'execute_method',
        },
    );

    my %isa = (
        Array   => 'ArrayRef[Str]',
        Hash    => 'HashRef[Int]',
        Counter => 'Int',
        Number  => 'Num',
        Bool    => 'Bool',
        String  => 'Str',
        Code    => 'CodeRef',
    );

    my %default = (
        Array   => [],
        Hash    => {},
        Counter => 0,
        Number  => 0.0,
        Bool    => 1,
        String  => '',
        Code    => sub { },
    );

    for my $trait (keys %default) {
        my $class_name = "Native::$trait";
        my $handles = $handles{$trait};
        my $attr_class = Moose::Util::with_traits(
            'Moose::Meta::Attribute',
            "Moose::Meta::Attribute::Native::Trait::$trait",
        );
        Moose::Meta::Class->create(
            $class_name,
            superclasses => ['Moose::Object'],
            attributes   => [
                $attr_class->new(
                    'nonlazy',
                    is      => 'ro',
                    isa     => $isa{$trait},
                    default => sub { $default{$trait} },
                    handles => {
                        map {; "nonlazy_$_" => $handles->{$_} } keys %$handles
                    },
                ),
                $attr_class->new(
                    'lazy',
                    is      => 'ro',
                    isa     => $isa{$trait},
                    lazy    => 1,
                    default => sub { $default{$trait} },
                    handles => {
                        map {; "lazy_$_" => $handles->{$_} } keys %$handles
                    },
                ),
            ],
        );
        close_over_ok($class_name, $_) for (
            'new',
            map {; "nonlazy_$_", "lazy_$_" } keys %$handles
        );
    }
}

{
    package WithInitializer;
    use Moose;

    has foo => (
        is          => 'ro',
        isa         => 'Str',
        initializer => sub { },
    );

    has bar => (
        is          => 'ro',
        isa         => 'Str',
        lazy        => 1,
        default     => sub { 'a' },
        initializer => sub { },
    );

    __PACKAGE__->meta->make_immutable;
}

close_over_ok('WithInitializer', 'foo');
{ local $TODO = "initializer still closes over things";
close_over_ok('WithInitializer', $_) for qw(new bar);
}

BEGIN {
    package CustomErrorClass;
    use Moose;
    extends 'Moose::Error::Default';
}

{
    package WithCustomErrorClass;
    use metaclass (
        metaclass => 'Moose::Meta::Class',
        error_class => 'CustomErrorClass',
    );
    use Moose;

    has foo => (
        is  => 'ro',
        isa => 'Str',
    );

    __PACKAGE__->meta->make_immutable;
}

{ local $TODO = "custom error classes still close over things";
close_over_ok('WithCustomErrorClass', $_) for qw(new foo);
}

done_testing;
