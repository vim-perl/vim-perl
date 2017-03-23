#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Fatal;
$| = 1;



# =begin testing SETUP
use Test::Requires {
    'Locale::US'     => '0',
    'Regexp::Common' => '0',
};



# =begin testing SETUP
{

  package Address;
  use Moose;
  use Moose::Util::TypeConstraints;

  use Locale::US;
  use Regexp::Common 'zip';

  my $STATES = Locale::US->new;
  subtype 'USState'
      => as Str
      => where {
             (    exists $STATES->{code2state}{ uc($_) }
               || exists $STATES->{state2code}{ uc($_) } );
         };

  subtype 'USZipCode'
      => as Value
      => where {
             /^$RE{zip}{US}{-extended => 'allow'}$/;
         };

  has 'street'   => ( is => 'rw', isa => 'Str' );
  has 'city'     => ( is => 'rw', isa => 'Str' );
  has 'state'    => ( is => 'rw', isa => 'USState' );
  has 'zip_code' => ( is => 'rw', isa => 'USZipCode' );

  package Company;
  use Moose;
  use Moose::Util::TypeConstraints;

  has 'name' => ( is => 'rw', isa => 'Str', required => 1 );
  has 'address'   => ( is => 'rw', isa => 'Address' );
  has 'employees' => (
      is      => 'rw',
      isa     => 'ArrayRef[Employee]',
      default => sub { [] },
  );

  sub BUILD {
      my ( $self, $params ) = @_;
      foreach my $employee ( @{ $self->employees } ) {
          $employee->employer($self);
      }
  }

  after 'employees' => sub {
      my ( $self, $employees ) = @_;
      return unless $employees;
      foreach my $employee ( @$employees ) {
          $employee->employer($self);
      }
  };

  package Person;
  use Moose;

  has 'first_name' => ( is => 'rw', isa => 'Str', required => 1 );
  has 'last_name'  => ( is => 'rw', isa => 'Str', required => 1 );
  has 'middle_initial' => (
      is        => 'rw', isa => 'Str',
      predicate => 'has_middle_initial'
  );
  has 'address' => ( is => 'rw', isa => 'Address' );

  sub full_name {
      my $self = shift;
      return $self->first_name
          . (
          $self->has_middle_initial
          ? ' ' . $self->middle_initial . '. '
          : ' '
          ) . $self->last_name;
  }

  package Employee;
  use Moose;

  extends 'Person';

  has 'title'    => ( is => 'rw', isa => 'Str',     required => 1 );
  has 'employer' => ( is => 'rw', isa => 'Company', weak_ref => 1 );

  override 'full_name' => sub {
      my $self = shift;
      super() . ', ' . $self->title;
  };
}



# =begin testing
{
{
    package Company;

    sub get_employee_count { scalar @{(shift)->employees} }
}

use Scalar::Util 'isweak';

my $ii;
is(
    exception {
        $ii = Company->new(
            {
                name    => 'Infinity Interactive',
                address => Address->new(
                    street   => '565 Plandome Rd., Suite 307',
                    city     => 'Manhasset',
                    state    => 'NY',
                    zip_code => '11030'
                ),
                employees => [
                    Employee->new(
                        first_name => 'Jeremy',
                        last_name  => 'Shao',
                        title      => 'President / Senior Consultant',
                        address    => Address->new(
                            city => 'Manhasset', state => 'NY'
                        )
                    ),
                    Employee->new(
                        first_name => 'Tommy',
                        last_name  => 'Lee',
                        title      => 'Vice President / Senior Developer',
                        address =>
                            Address->new( city => 'New York', state => 'NY' )
                    ),
                    Employee->new(
                        first_name     => 'Stevan',
                        middle_initial => 'C',
                        last_name      => 'Little',
                        title          => 'Senior Developer',
                        address =>
                            Address->new( city => 'Madison', state => 'CT' )
                    ),
                ]
            }
        );
    },
    undef,
    '... created the entire company successfully'
);

isa_ok( $ii, 'Company' );

is( $ii->name, 'Infinity Interactive',
    '... got the right name for the company' );

isa_ok( $ii->address, 'Address' );
is( $ii->address->street, '565 Plandome Rd., Suite 307',
    '... got the right street address' );
is( $ii->address->city,     'Manhasset', '... got the right city' );
is( $ii->address->state,    'NY',        '... got the right state' );
is( $ii->address->zip_code, 11030,       '... got the zip code' );

is( $ii->get_employee_count, 3, '... got the right employee count' );

# employee #1

isa_ok( $ii->employees->[0], 'Employee' );
isa_ok( $ii->employees->[0], 'Person' );

is( $ii->employees->[0]->first_name, 'Jeremy',
    '... got the right first name' );
is( $ii->employees->[0]->last_name, 'Shao', '... got the right last name' );
ok( !$ii->employees->[0]->has_middle_initial, '... no middle initial' );
is( $ii->employees->[0]->middle_initial, undef,
    '... got the right middle initial value' );
is( $ii->employees->[0]->full_name,
    'Jeremy Shao, President / Senior Consultant',
    '... got the right full name' );
is( $ii->employees->[0]->title, 'President / Senior Consultant',
    '... got the right title' );
is( $ii->employees->[0]->employer, $ii, '... got the right company' );
ok( isweak( $ii->employees->[0]->{employer} ),
    '... the company is a weak-ref' );

isa_ok( $ii->employees->[0]->address, 'Address' );
is( $ii->employees->[0]->address->city, 'Manhasset',
    '... got the right city' );
is( $ii->employees->[0]->address->state, 'NY', '... got the right state' );

# employee #2

isa_ok( $ii->employees->[1], 'Employee' );
isa_ok( $ii->employees->[1], 'Person' );

is( $ii->employees->[1]->first_name, 'Tommy',
    '... got the right first name' );
is( $ii->employees->[1]->last_name, 'Lee', '... got the right last name' );
ok( !$ii->employees->[1]->has_middle_initial, '... no middle initial' );
is( $ii->employees->[1]->middle_initial, undef,
    '... got the right middle initial value' );
is( $ii->employees->[1]->full_name,
    'Tommy Lee, Vice President / Senior Developer',
    '... got the right full name' );
is( $ii->employees->[1]->title, 'Vice President / Senior Developer',
    '... got the right title' );
is( $ii->employees->[1]->employer, $ii, '... got the right company' );
ok( isweak( $ii->employees->[1]->{employer} ),
    '... the company is a weak-ref' );

isa_ok( $ii->employees->[1]->address, 'Address' );
is( $ii->employees->[1]->address->city, 'New York',
    '... got the right city' );
is( $ii->employees->[1]->address->state, 'NY', '... got the right state' );

# employee #3

isa_ok( $ii->employees->[2], 'Employee' );
isa_ok( $ii->employees->[2], 'Person' );

is( $ii->employees->[2]->first_name, 'Stevan',
    '... got the right first name' );
is( $ii->employees->[2]->last_name, 'Little', '... got the right last name' );
ok( $ii->employees->[2]->has_middle_initial, '... got middle initial' );
is( $ii->employees->[2]->middle_initial, 'C',
    '... got the right middle initial value' );
is( $ii->employees->[2]->full_name, 'Stevan C. Little, Senior Developer',
    '... got the right full name' );
is( $ii->employees->[2]->title, 'Senior Developer',
    '... got the right title' );
is( $ii->employees->[2]->employer, $ii, '... got the right company' );
ok( isweak( $ii->employees->[2]->{employer} ),
    '... the company is a weak-ref' );

isa_ok( $ii->employees->[2]->address, 'Address' );
is( $ii->employees->[2]->address->city, 'Madison', '... got the right city' );
is( $ii->employees->[2]->address->state, 'CT', '... got the right state' );

# create new company

my $new_company
    = Company->new( name => 'Infinity Interactive International' );
isa_ok( $new_company, 'Company' );

my $ii_employees = $ii->employees;
foreach my $employee (@$ii_employees) {
    is( $employee->employer, $ii, '... has the ii company' );
}

$new_company->employees($ii_employees);

foreach my $employee ( @{ $new_company->employees } ) {
    is( $employee->employer, $new_company,
        '... has the different company now' );
}

## check some error conditions for the subtypes

isnt(
    exception {
        Address->new( street => {} ),;
    },
    undef,
    '... we die correctly with bad args'
);

isnt(
    exception {
        Address->new( city => {} ),;
    },
    undef,
    '... we die correctly with bad args'
);

isnt(
    exception {
        Address->new( state => 'British Columbia' ),;
    },
    undef,
    '... we die correctly with bad args'
);

is(
    exception {
        Address->new( state => 'Connecticut' ),;
    },
    undef,
    '... we live correctly with good args'
);

isnt(
    exception {
        Address->new( zip_code => 'AF5J6$' ),;
    },
    undef,
    '... we die correctly with bad args'
);

is(
    exception {
        Address->new( zip_code => '06443' ),;
    },
    undef,
    '... we live correctly with good args'
);

isnt(
    exception {
        Company->new(),;
    },
    undef,
    '... we die correctly without good args'
);

is(
    exception {
        Company->new( name => 'Foo' ),;
    },
    undef,
    '... we live correctly without good args'
);

isnt(
    exception {
        Company->new( name => 'Foo', employees => [ Person->new ] ),;
    },
    undef,
    '... we die correctly with good args'
);

is(
    exception {
        Company->new( name => 'Foo', employees => [] ),;
    },
    undef,
    '... we live correctly with good args'
);
}




1;
