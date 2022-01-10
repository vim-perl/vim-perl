#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Requires {
    'DBM::Deep' => '1.0003', # skip all if not installed
    'DateTime::Format::MySQL' => '0.01',
};

use Test::Fatal;

BEGIN {
    # in case there are leftovers
    unlink('newswriter.db') if -e 'newswriter.db';
}

END {
    unlink('newswriter.db') if -e 'newswriter.db';
}


=pod

This example creates a very basic Object Database which
links in the instances created with a backend store
(a DBM::Deep hash). It is by no means to be taken seriously
as a real-world ODB, but is a proof of concept of the flexibility
of the ::Instance protocol.

=cut

BEGIN {

    package MooseX::POOP::Meta::Instance;
    use Moose;

    use DBM::Deep;

    extends 'Moose::Meta::Instance';

    {
        my %INSTANCE_COUNTERS;

        my $db = DBM::Deep->new({
            file      => "newswriter.db",
            autobless => 1,
            locking   => 1,
        });

        sub _reload_db {
            #use Data::Dumper;
            #warn Dumper $db;
            $db = undef;
            $db = DBM::Deep->new({
                file      => "newswriter.db",
                autobless => 1,
                locking   => 1,
            });
        }

        sub create_instance {
            my $self  = shift;
            my $class = $self->associated_metaclass->name;
            my $oid   = ++$INSTANCE_COUNTERS{$class};

            $db->{$class}->[($oid - 1)] = {};

            bless {
                oid      => $oid,
                instance => $db->{$class}->[($oid - 1)]
            }, $class;
        }

        sub find_instance {
            my ($self, $oid) = @_;
            my $instance = $db->{$self->associated_metaclass->name}->[($oid - 1)];

            bless {
                oid      => $oid,
                instance => $instance,
            }, $self->associated_metaclass->name;
        }

        sub clone_instance {
            my ($self, $instance) = @_;

            my $class = $self->{meta}->name;
            my $oid   = ++$INSTANCE_COUNTERS{$class};

            my $clone = tied($instance)->clone;

            bless {
                oid      => $oid,
                instance => $clone,
            }, $class;
        }
    }

    sub get_instance_oid {
        my ($self, $instance) = @_;
        $instance->{oid};
    }

    sub get_slot_value {
        my ($self, $instance, $slot_name) = @_;
        return $instance->{instance}->{$slot_name};
    }

    sub set_slot_value {
        my ($self, $instance, $slot_name, $value) = @_;
        $instance->{instance}->{$slot_name} = $value;
    }

    sub is_slot_initialized {
        my ($self, $instance, $slot_name, $value) = @_;
        exists $instance->{instance}->{$slot_name} ? 1 : 0;
    }

    sub weaken_slot_value {
        confess "Not sure how well DBM::Deep plays with weak refs, Rob says 'Write a test'";
    }

    sub inline_slot_access {
        my ($self, $instance, $slot_name) = @_;
        sprintf "%s->{instance}->{%s}", $instance, $slot_name;
    }

    package MooseX::POOP::Meta::Class;
    use Moose;

    extends 'Moose::Meta::Class';

    override '_construct_instance' => sub {
        my $class = shift;
        my $params = @_ == 1 ? $_[0] : {@_};
        return $class->get_meta_instance->find_instance($params->{oid})
            if $params->{oid};
        super();
    };

}
{
    package MooseX::POOP::Object;
    use metaclass 'MooseX::POOP::Meta::Class' => (
        instance_metaclass => 'MooseX::POOP::Meta::Instance'
    );
    use Moose;

    sub oid {
        my $self = shift;
        $self->meta
             ->get_meta_instance
             ->get_instance_oid($self);
    }

}
{
    package Newswriter::Author;
    use Moose;

    extends 'MooseX::POOP::Object';

    has 'first_name' => (is => 'rw', isa => 'Str');
    has 'last_name'  => (is => 'rw', isa => 'Str');

    package Newswriter::Article;
    use Moose;
    use Moose::Util::TypeConstraints;

    use DateTime::Format::MySQL;

    extends 'MooseX::POOP::Object';

    subtype 'Headline'
        => as 'Str'
        => where { length($_) < 100 };

    subtype 'Summary'
        => as 'Str'
        => where { length($_) < 255 };

    subtype 'DateTimeFormatString'
        => as 'Str'
        => where { DateTime::Format::MySQL->parse_datetime($_) };

    enum 'Status' => qw(draft posted pending archive);

    has 'headline' => (is => 'rw', isa => 'Headline');
    has 'summary'  => (is => 'rw', isa => 'Summary');
    has 'article'  => (is => 'rw', isa => 'Str');

    has 'start_date' => (is => 'rw', isa => 'DateTimeFormatString');
    has 'end_date'   => (is => 'rw', isa => 'DateTimeFormatString');

    has 'author' => (is => 'rw', isa => 'Newswriter::Author');

    has 'status' => (is => 'rw', isa => 'Status');

    around 'start_date', 'end_date' => sub {
        my $c    = shift;
        my $self = shift;
        $c->($self, DateTime::Format::MySQL->format_datetime($_[0])) if @_;
        DateTime::Format::MySQL->parse_datetime($c->($self) || return undef);
    };
}

{ # check the meta stuff first
    isa_ok(MooseX::POOP::Object->meta, 'MooseX::POOP::Meta::Class');
    isa_ok(MooseX::POOP::Object->meta, 'Moose::Meta::Class');
    isa_ok(MooseX::POOP::Object->meta, 'Class::MOP::Class');

    is(MooseX::POOP::Object->meta->instance_metaclass,
      'MooseX::POOP::Meta::Instance',
      '... got the right instance metaclass name');

    isa_ok(MooseX::POOP::Object->meta->get_meta_instance, 'MooseX::POOP::Meta::Instance');

    my $base = MooseX::POOP::Object->new;
    isa_ok($base, 'MooseX::POOP::Object');
    isa_ok($base, 'Moose::Object');

    isa_ok($base->meta, 'MooseX::POOP::Meta::Class');
    isa_ok($base->meta, 'Moose::Meta::Class');
    isa_ok($base->meta, 'Class::MOP::Class');

    is($base->meta->instance_metaclass,
      'MooseX::POOP::Meta::Instance',
      '... got the right instance metaclass name');

    isa_ok($base->meta->get_meta_instance, 'MooseX::POOP::Meta::Instance');
}

my $article_oid;
{
    my $article;
    is( exception {
        $article = Newswriter::Article->new(
            headline => 'Home Office Redecorated',
            summary  => 'The home office was recently redecorated to match the new company colors',
            article  => '...',

            author => Newswriter::Author->new(
                first_name => 'Truman',
                last_name  => 'Capote'
            ),

            status => 'pending'
        );
    }, undef, '... created my article successfully' );
    isa_ok($article, 'Newswriter::Article');
    isa_ok($article, 'MooseX::POOP::Object');

    is( exception {
        $article->start_date(DateTime->new(year => 2006, month => 6, day => 10));
        $article->end_date(DateTime->new(year => 2006, month => 6, day => 17));
    }, undef, '... add the article date-time stuff' );

    ## check some meta stuff

    isa_ok($article->meta, 'MooseX::POOP::Meta::Class');
    isa_ok($article->meta, 'Moose::Meta::Class');
    isa_ok($article->meta, 'Class::MOP::Class');

    is($article->meta->instance_metaclass,
      'MooseX::POOP::Meta::Instance',
      '... got the right instance metaclass name');

    isa_ok($article->meta->get_meta_instance, 'MooseX::POOP::Meta::Instance');

    ok($article->oid, '... got a oid for the article');

    $article_oid = $article->oid;

    is($article->headline,
       'Home Office Redecorated',
       '... got the right headline');
    is($article->summary,
       'The home office was recently redecorated to match the new company colors',
       '... got the right summary');
    is($article->article, '...', '... got the right article');

    isa_ok($article->start_date, 'DateTime');
    isa_ok($article->end_date,   'DateTime');

    isa_ok($article->author, 'Newswriter::Author');
    is($article->author->first_name, 'Truman', '... got the right author first name');
    is($article->author->last_name, 'Capote', '... got the right author last name');

    is($article->status, 'pending', '... got the right status');
}

MooseX::POOP::Meta::Instance->_reload_db();

my $article2_oid;
{
    my $article2;
    is( exception {
        $article2 = Newswriter::Article->new(
            headline => 'Company wins Lottery',
            summary  => 'An email was received today that informed the company we have won the lottery',
            article  => 'WoW',

            author => Newswriter::Author->new(
                first_name => 'Katie',
                last_name  => 'Couric'
            ),

            status => 'posted'
        );
    }, undef, '... created my article successfully' );
    isa_ok($article2, 'Newswriter::Article');
    isa_ok($article2, 'MooseX::POOP::Object');

    $article2_oid = $article2->oid;

    is($article2->headline,
       'Company wins Lottery',
       '... got the right headline');
    is($article2->summary,
       'An email was received today that informed the company we have won the lottery',
       '... got the right summary');
    is($article2->article, 'WoW', '... got the right article');

    ok(!$article2->start_date, '... these two dates are unassigned');
    ok(!$article2->end_date,   '... these two dates are unassigned');

    isa_ok($article2->author, 'Newswriter::Author');
    is($article2->author->first_name, 'Katie', '... got the right author first name');
    is($article2->author->last_name, 'Couric', '... got the right author last name');

    is($article2->status, 'posted', '... got the right status');

    ## orig-article

    my $article;
    is( exception {
        $article = Newswriter::Article->new(oid => $article_oid);
    }, undef, '... (re)-created my article successfully' );
    isa_ok($article, 'Newswriter::Article');
    isa_ok($article, 'MooseX::POOP::Object');

    is($article->oid, $article_oid, '... got a oid for the article');

    is($article->headline,
       'Home Office Redecorated',
       '... got the right headline');
    is($article->summary,
       'The home office was recently redecorated to match the new company colors',
       '... got the right summary');
    is($article->article, '...', '... got the right article');

    isa_ok($article->start_date, 'DateTime');
    isa_ok($article->end_date,   'DateTime');

    isa_ok($article->author, 'Newswriter::Author');
    is($article->author->first_name, 'Truman', '... got the right author first name');
    is($article->author->last_name, 'Capote', '... got the right author last name');

    is( exception {
        $article->author->first_name('Dan');
        $article->author->last_name('Rather');
    }, undef, '... changed the value ok' );

    is($article->author->first_name, 'Dan', '... got the changed author first name');
    is($article->author->last_name, 'Rather', '... got the changed author last name');

    is($article->status, 'pending', '... got the right status');
}

MooseX::POOP::Meta::Instance->_reload_db();

{
    my $article;
    is( exception {
        $article = Newswriter::Article->new(oid => $article_oid);
    }, undef, '... (re)-created my article successfully' );
    isa_ok($article, 'Newswriter::Article');
    isa_ok($article, 'MooseX::POOP::Object');

    is($article->oid, $article_oid, '... got a oid for the article');

    is($article->headline,
       'Home Office Redecorated',
       '... got the right headline');
    is($article->summary,
       'The home office was recently redecorated to match the new company colors',
       '... got the right summary');
    is($article->article, '...', '... got the right article');

    isa_ok($article->start_date, 'DateTime');
    isa_ok($article->end_date,   'DateTime');

    isa_ok($article->author, 'Newswriter::Author');
    is($article->author->first_name, 'Dan', '... got the changed author first name');
    is($article->author->last_name, 'Rather', '... got the changed author last name');

    is($article->status, 'pending', '... got the right status');

    my $article2;
    is( exception {
        $article2 = Newswriter::Article->new(oid => $article2_oid);
    }, undef, '... (re)-created my article successfully' );
    isa_ok($article2, 'Newswriter::Article');
    isa_ok($article2, 'MooseX::POOP::Object');

    is($article2->oid, $article2_oid, '... got a oid for the article');

    is($article2->headline,
       'Company wins Lottery',
       '... got the right headline');
    is($article2->summary,
       'An email was received today that informed the company we have won the lottery',
       '... got the right summary');
    is($article2->article, 'WoW', '... got the right article');

    ok(!$article2->start_date, '... these two dates are unassigned');
    ok(!$article2->end_date,   '... these two dates are unassigned');

    isa_ok($article2->author, 'Newswriter::Author');
    is($article2->author->first_name, 'Katie', '... got the right author first name');
    is($article2->author->last_name, 'Couric', '... got the right author last name');

    is($article2->status, 'posted', '... got the right status');

}

done_testing;
