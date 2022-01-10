package Data::Printer;
use strict;
use warnings;
use Term::ANSIColor qw(color colored);
use Scalar::Util;
use Sort::Naturally;
use Carp qw(croak);
use Clone::PP qw(clone);
use if $] >= 5.010, 'Hash::Util::FieldHash' => qw(fieldhash);
use if $] < 5.010, 'Hash::Util::FieldHash::Compat' => qw(fieldhash);
use File::Spec;
use File::HomeDir ();
use Fcntl;
use version 0.77 ();

our $VERSION = '0.35';

BEGIN {
    if ($^O =~ /Win32/i) {
        require Win32::Console::ANSI;
        Win32::Console::ANSI->import;
    }
}


# defaults
my $BREAK = "\n";
my $properties = {
    'name'           => 'var',
    'indent'         => 4,
    'index'          => 1,
    'max_depth'      => 0,
    'multiline'      => 1,
    'sort_keys'      => 1,
    'deparse'        => 0,
    'hash_separator' => '   ',
    'separator'      => ',',
    'end_separator'  => 0,
    'show_tied'      => 1,
    'show_tainted'   => 1,
    'show_weak'      => 1,
    'show_readonly'  => 0,
    'show_lvalue'    => 1,
    'print_escapes'  => 0,
    'quote_keys'     => 'auto',
    'use_prototypes' => 1,
    'output'         => 'stderr',
    'return_value'   => 'dump',       # also 'void' or 'pass'
    'colored'        => 'auto',       # also 0 or 1
    'caller_info'    => 0,
    'caller_message' => 'Printing in line __LINE__ of __FILENAME__:',
    'class_method'   => '_data_printer', # use a specific dump method, if available
    'color'          => {
        'array'       => 'bright_white',
        'number'      => 'bright_blue',
        'string'      => 'bright_yellow',
        'class'       => 'bright_green',
        'method'      => 'bright_green',
        'undef'       => 'bright_red',
        'hash'        => 'magenta',
        'regex'       => 'yellow',
        'code'        => 'green',
        'glob'        => 'bright_cyan',
        'vstring'     => 'bright_blue',
        'lvalue'      => 'bright_white',
        'format'      => 'bright_cyan',
        'repeated'    => 'white on_red',
        'caller_info' => 'bright_cyan',
        'weak'        => 'cyan',
        'tainted'     => 'red',
        'escaped'     => 'bright_red',
        'unknown'     => 'bright_yellow on_blue',
    },
    'class' => {
        inherited    => 'none',   # also 'all', 'public' or 'private'
        universal    => 1,
        parents      => 1,
        linear_isa   => 'auto',
        expand       => 1,        # how many levels to expand. 0 for none, 'all' for all
        internals    => 1,
        export       => 1,
        sort_methods => 1,
        show_methods => 'all',    # also 'none', 'public', 'private'
        show_reftype => 0,
        _depth       => 0,        # used internally
    },
    'filters' => {
        # The IO ref type isn't supported as you can't actually create one,
        # any handle you make is automatically blessed into an IO::* object,
        # and those are separately handled.
        SCALAR  => [ \&SCALAR   ],
        ARRAY   => [ \&ARRAY    ],
        HASH    => [ \&HASH     ],
        REF     => [ \&REF      ],
        CODE    => [ \&CODE     ],
        GLOB    => [ \&GLOB     ],
        VSTRING => [ \&VSTRING  ],
        LVALUE  => [ \&LVALUE ],
        FORMAT  => [ \&FORMAT ],
        Regexp  => [ \&Regexp   ],
        -unknown=> [ \&_unknown ],
        -class  => [ \&_class   ],
    },

    _output          => *STDERR,     # used internally
    _current_indent  => 0,           # used internally
    _linebreak       => \$BREAK,     # used internally
    _seen            => {},          # used internally
    _seen_override   => {},          # used internally
    _depth           => 0,           # used internally
    _tie             => 0,           # used internally
};


sub import {
    my $class = shift;
    my $args;
    if (scalar @_) {
        $args = @_ == 1 ? shift : {@_};
        croak 'Data::Printer can receive either a hash or a hash reference.'
            unless ref $args and ref $args eq 'HASH';
    }

    # the RC file overrides the defaults,
    # (and we load it only once)
    unless( exists $properties->{_initialized} ) {
        _load_rc_file($args);
        $properties->{_initialized} = 1;
    }

    # and 'use' arguments override the RC file
    if ($args) {
        $properties = _merge( $args );
    }

    my $exported = ($properties->{use_prototypes} ? \&p : \&np );
    my $imported = $properties->{alias} || 'p';
    my $caller = caller;
    no strict 'refs';
    *{"$caller\::$imported"} = $exported;
}


sub p (\[@$%&];%) {
    return _print_and_return( $_[0], _data_printer(!!defined wantarray, @_) );
}

# np() is a p() clone without prototypes.
# Just like regular Data::Dumper, this version
# expects a reference as its first argument.
# We make a single exception for when we only
# get one argument, in which case we ref it
# for the user and keep going.
sub np  {
    my $item = shift;

    if (!ref $item && @_ == 0) {
        my $item_value = $item;
        $item = \$item_value;
    }

    return _print_and_return( $item, _data_printer(!!defined wantarray, $item, @_) );
}

sub _print_and_return {
    my ($item, $dump, $p) = @_;

    if ( $p->{return_value} eq 'pass' ) {
        print { $p->{_output} } $dump . $/;

        my $ref = ref $item;
        if ($ref eq 'ARRAY') {
            return @{ $item };
        }
        elsif ($ref eq 'HASH') {
            return %{ $item };
        }
        elsif ( grep { $ref eq $_ } qw(REF SCALAR CODE Regexp GLOB VSTRING) ) {
            return $$item;
        }
        else {
            return $item;
        }
    }
    elsif ( $p->{return_value} eq 'void' ) {
        print { $p->{_output} } $dump . $/;
        return;
    }
    else {
        print { $p->{_output} } $dump . $/ unless defined wantarray;
        return $dump;
    }
}

sub _data_printer {
    my $wantarray = shift;

    croak 'When calling p() without prototypes, please pass arguments as references'
        unless ref $_[0];

    my ($item, %local_properties) = @_;
    local %ENV = %ENV;

    my $p = _merge(\%local_properties);
    unless ($p->{multiline}) {
        $BREAK = ' ';
        $p->{'indent'} = 0;
        $p->{'index'}  = 0;
    }

    # We disable colors if colored is set to false.
    # If set to "auto", we disable colors if the user
    # set ANSI_COLORS_DISABLED or if we're either
    # returning the value (instead of printing) or
    # being piped to another command.
    if ( !$p->{colored}
          or ($p->{colored} eq 'auto'
              and (exists $ENV{ANSI_COLORS_DISABLED}
                   or $wantarray
                   or not -t $p->{_output}
                  )
          )
    ) {
        $ENV{ANSI_COLORS_DISABLED} = 1;
    }
    else {
        delete $ENV{ANSI_COLORS_DISABLED};
    }

    my $out = color('reset');

    if ( $p->{caller_info} and $p->{_depth} == 0 ) {
        $out .= _get_info_message($p);
    }

    $out .= _p( $item, $p );
    return ($out, $p);
}


sub _p {
    my ($item, $p) = @_;
    my $ref = (defined $p->{_reftype} ? $p->{_reftype} : ref $item);
    my $tie;

    my $string = '';

    # Object's unique ID, avoiding circular structures
    my $id = _object_id( $item );
    if ( exists $p->{_seen}->{$id} ) {
        if ( not defined $p->{_reftype} ) {
            return colored($p->{_seen}->{$id}, $p->{color}->{repeated});
        }
    }
    # some filters don't want us to show their repeated refs
    elsif( !exists $p->{_seen_override}{$ref} ) {
        $p->{_seen}->{$id} = $p->{name};
    }

    delete $p->{_reftype}; # abort override

    # globs don't play nice
    $ref = 'GLOB' if "$item" =~ /GLOB\([^()]+\)$/;


    # filter item (if user set a filter for it)
    my $found;
    if ( exists $p->{filters}->{$ref} ) {
        foreach my $filter ( @{ $p->{filters}->{$ref} } ) {
            if ( defined (my $result = $filter->($item, $p)) ) {
                $string .= $result;
                $found = 1;
                last;
            }
        }
    }

    if (not $found and Scalar::Util::blessed($item) ) {
        # let '-class' filters have a go
        foreach my $filter ( @{ $p->{filters}->{'-class'} } ) {
            if ( defined (my $result = $filter->($item, $p)) ) {
                $string .= $result;
                $found = 1;
                last;
            }
        }
    }
    
    if ( not $found ) {
        # if it's not a class and not a known core type, we must be in
        # a future perl with some type we're unaware of
        foreach my $filter ( @{ $p->{filters}->{'-unknown'} } ) {
            if ( defined (my $result = $filter->($item, $p)) ) {
                $string .= $result;
                last;
            }
        }
    }

    if ($p->{show_tied} and $p->{_tie} ) {
        $string .= ' (tied to ' . $p->{_tie} . ')';
        $p->{_tie} = '';
    }

    return $string;
}



######################################
## Default filters
######################################

sub SCALAR {
    my ($item, $p) = @_;
    my $string = '';

    if (not defined $$item) {
        $string .= colored('undef', $p->{color}->{'undef'});
    }
    elsif (Scalar::Util::looks_like_number($$item)) {
        $string .= colored($$item, $p->{color}->{'number'});
    }
    else {
        my $val = _escape_chars($$item, $p->{color}{string}, $p);

        $string .= q["] . colored($val, $p->{color}->{'string'}) . q["];
    }

    $string .= ' ' . colored('(TAINTED)', $p->{color}->{'tainted'})
        if $p->{show_tainted} and Scalar::Util::tainted($$item);

    $p->{_tie} = ref tied $$item;

    if ($p->{show_readonly} and &Internals::SvREADONLY( $item )) {
        $string .= ' (read-only)';
    }

    return $string;
}

sub _escape_chars {
    my ($str, $orig_color, $p) = @_;

    $orig_color   = color( $orig_color );
    my $esc_color = color( $p->{color}{escaped} );

    if ($p->{print_escapes}) {
        $str =~ s/\e/$esc_color\\e$orig_color/g;

        my %escaped = (
            "\n" => '\n',
            "\r" => '\r',
            "\t" => '\t',
            "\f" => '\f',
            "\b" => '\b',
            "\a" => '\a',
        );
        foreach my $k ( keys %escaped ) {
            $str =~ s/$k/$esc_color$escaped{$k}$orig_color/g;
        }
    }
    # always escape the null character
    $str =~ s/\0/$esc_color\\0$orig_color/g;

    return $str;
}


sub ARRAY {
    my ($item, $p) = @_;
    my $string = '';
    $p->{_depth}++;

    if ( $p->{max_depth} and $p->{_depth} > $p->{max_depth} ) {
        $string .= '[ ... ]';
    }
    elsif (not @$item) {
        $string .= '[]';
    }
    else {
        $string .= "[$BREAK";
        $p->{_current_indent} += $p->{indent};

        foreach my $i (0 .. $#{$item} ) {
            $p->{name} .= "[$i]";

            my $array_elem = $item->[$i];
            $string .= (' ' x $p->{_current_indent});
            if ($p->{'index'}) {
                $string .= colored(
                             sprintf("%-*s", 3 + length($#{$item}), "[$i]"),
                             $p->{color}->{'array'}
                       );
            }

            my $ref = ref $array_elem;

            # scalar references should be re-referenced
            # to gain a '\' sign in front of them
            if (!$ref or $ref eq 'SCALAR') {
                $string .= _p( \$array_elem, $p );
            }
            else {
                $string .= _p( $array_elem, $p );
            }
            $string .= ' ' . colored('(weak)', $p->{color}->{'weak'})
                if $ref and Scalar::Util::isweak($item->[$i]) and $p->{show_weak};

            $string .= $p->{separator}
              if $i < $#{$item} || $p->{end_separator};

            $string .= $BREAK;

            my $size = 2 + length($i); # [10], [100], etc
            substr $p->{name}, -$size, $size, '';
        }
        $p->{_current_indent} -= $p->{indent};
        $string .= (' ' x $p->{_current_indent}) . "]";
    }

    $p->{_tie} = ref tied @$item;
    $p->{_depth}--;

    return $string;
}


sub REF {
    my ($item, $p) = @_;
    my $string = '';

    # look-ahead, add a '\' only if it's not an object
    if (my $ref_ahead = ref $$item ) {
        $string .= '\\ ' if grep { $_ eq $ref_ahead }
            qw(SCALAR CODE Regexp ARRAY HASH GLOB REF);
    }
    $string .= _p($$item, $p);

    $string .= ' ' . colored('(weak)', $p->{color}->{'weak'})
        if Scalar::Util::isweak($$item) and $p->{show_weak};

    return $string;
}


sub CODE {
    my ($item, $p) = @_;
    my $string = '';

    my $code = 'sub { ... }';
    if ($p->{deparse}) {
        $code = _deparse( $item, $p );
    }
    $string .= colored($code, $p->{color}->{'code'});
    return $string;
}


sub HASH {
    my ($item, $p) = @_;
    my $string = '';

    $p->{_depth}++;

    if ( $p->{max_depth} and $p->{_depth} > $p->{max_depth} ) {
        $string .= '{ ... }';
    }
    elsif (not keys %$item) {
        $string .= '{}';
    }
    else {
        $string .= "{$BREAK";
        $p->{_current_indent} += $p->{indent};

        my $total_keys  = scalar keys %$item;
        my $len         = 0;
        my $multiline   = $p->{multiline};
        my $hash_color  = $p->{color}{hash};
        my $quote_keys  = $p->{quote_keys};

        my @keys = ();

        # first pass, preparing keys to display (and getting largest key size)
        foreach my $key ($p->{sort_keys} ? nsort keys %$item : keys %$item ) {
            my $new_key = _escape_chars($key, $hash_color, $p);
            my $colored = colored( $new_key, $hash_color );

            # wrap in uncolored single quotes if there's
            # any space or escaped characters
            if ( $quote_keys
                  and (
                        $quote_keys ne 'auto'
                        or (
                             $key eq q()
                             or $new_key ne $key
                             or $new_key =~ /\s|\n|\t|\r/
                        )
                  )
            ) {
                $colored = qq['$colored'];
            }

            push @keys, {
                raw     => $key,
                colored => $colored,
            };

            # length of the largest key is used for indenting
            if ($multiline) {
                my $l = length $colored;
                $len = $l if $l > $len;
            }
        }

        # second pass, traversing and rendering
        foreach my $key (@keys) {
            my $raw_key     = $key->{raw};
            my $colored_key = $key->{colored};
            my $element     = $item->{$raw_key};
            $p->{name}     .= "{$raw_key}";

            $string .= (' ' x $p->{_current_indent})
                     . sprintf("%-*s", $len, $colored_key)
                     . $p->{hash_separator}
                     ;

            my $ref = ref $element;
            # scalar references should be re-referenced
            # to gain a '\' sign in front of them
            if (!$ref or $ref eq 'SCALAR') {
                $string .= _p( \$element, $p );
            }
            else {
                $string .= _p( $element, $p );
            }

            $string .= ' ' . colored('(weak)', $p->{color}->{'weak'})
                if $ref
                  and $p->{show_weak}
                  and Scalar::Util::isweak($item->{$raw_key});

            $string .= $p->{separator}
              if --$total_keys > 0 || $p->{end_separator};

            $string .= $BREAK;

            my $size = 2 + length($raw_key); # {foo}, {z}, etc
            substr $p->{name}, -$size, $size, '';
        }
        $p->{_current_indent} -= $p->{indent};
        $string .= (' ' x $p->{_current_indent}) . "}";
    }

    $p->{_tie} = ref tied %$item;
    $p->{_depth}--;

    return $string;
}


sub Regexp {
    my ($item, $p) = @_;
    my $string = '';

    my $val = "$item";
    # a regex to parse a regex. Talk about full circle :)
    # note: we are not validating anything, just grabbing modifiers
    if ($val =~ m/\(\?\^?([uladxismpogce]*)(?:\-[uladxismpogce]+)?:(.*)\)/s) {
        my ($modifiers, $val) = ($1, $2);
        $string .= colored($val, $p->{color}->{'regex'});
        if ($modifiers) {
            $string .= "  (modifiers: $modifiers)";
        }
    }
    else {
        croak "Unrecognized regex $val. Please submit a bug report for Data::Printer.";
    }
    return $string;
}

sub VSTRING {
    my ($item, $p) = @_;
    my $string = '';
    $string .= colored(version->declare($$item)->normal, $p->{color}->{'vstring'});
    return $string;
}

sub FORMAT {
    my ($item, $p) = @_;
    my $string = '';
    $string .= colored("FORMAT", $p->{color}->{'format'});
    return $string;
}

sub LVALUE {
    my ($item, $p) = @_;
    my $string = SCALAR( $item, $p );
    $string .= colored( ' (LVALUE)', $p->{color}{lvalue} )
        if $p->{show_lvalue};

    return $string;
}

sub GLOB {
    my ($item, $p) = @_;
    my $string = '';

    $string .= colored("$$item", $p->{color}->{'glob'});

    my $extra = '';

    # unfortunately, some systems (like Win32) do not
    # implement some of these flags (maybe not even
    # fcntl() itself, so we must wrap it.
    my $flags;
    eval { no warnings qw( unopened closed ); $flags = fcntl($$item, F_GETFL, 0) };
    if ($flags) {
        $extra .= ($flags & O_WRONLY) ? 'write-only'
                : ($flags & O_RDWR)   ? 'read/write'
                : 'read-only'
                ;

        # How to avoid croaking when the system
        # doesn't implement one of those, without skipping
        # the whole thing? Maybe there's a better way.
        # Solaris, for example, doesn't have O_ASYNC :(
        my %flags = ();
        eval { $flags{'append'}      = O_APPEND   };
        eval { $flags{'async'}       = O_ASYNC    }; # leont says this is the only one I should care for.
        eval { $flags{'create'}      = O_CREAT    };
        eval { $flags{'truncate'}    = O_TRUNC    };
        eval { $flags{'nonblocking'} = O_NONBLOCK };

        if (my @flags = grep { $flags & $flags{$_} } keys %flags) {
            $extra .= ", flags: @flags";
        }
        $extra .= ', ';
    }
    my @layers = ();
    eval { @layers = PerlIO::get_layers $$item }; # TODO: try PerlIO::Layers::get_layers (leont)
    unless ($@) {
        $extra .= "layers: @layers";
    }
    $string .= "  ($extra)" if $extra;

    $p->{_tie} = ref tied *$$item;
    return $string;
}


sub _unknown {
    my($item, $p) = @_;
    my $ref = ref $item;
    
    my $string = '';
    $string = colored($ref, $p->{color}->{'unknown'});
    return $string;
}

sub _class {
    my ($item, $p) = @_;
    my $ref = ref $item;

    # if the user specified a method to use instead, we do that
    if ( $p->{class_method} and my $method = $item->can($p->{class_method}) ) {
        return $method->($item, $p);
    }

    my $string = '';
    $p->{class}{_depth}++;

    $string .= colored($ref, $p->{color}->{'class'});

    if ( $p->{class}{show_reftype} ) {
        $string .= ' (' . colored(
            Scalar::Util::reftype($item),
            $p->{color}->{'class'}
        ) . ')';
    }

    if ($p->{class}{expand} eq 'all'
        or $p->{class}{expand} >= $p->{class}{_depth}
    ) {
        $string .= "  {$BREAK";

        $p->{_current_indent} += $p->{indent};

        if ($] >= 5.010) {
            require mro;
        } else {
            require MRO::Compat;
        }
        require Package::Stash;

        my $stash = Package::Stash->new($ref);

        if ( my @superclasses = @{$stash->get_symbol('@ISA')||[]} ) {
            if ($p->{class}{parents}) {
                $string .= (' ' x $p->{_current_indent})
                        . 'Parents       '
                        . join(', ', map { colored($_, $p->{color}->{'class'}) }
                                     @superclasses
                        ) . $BREAK;
            }

            if ( $p->{class}{linear_isa} and
                  (
                    ($p->{class}{linear_isa} eq 'auto' and @superclasses > 1)
                    or
                    ($p->{class}{linear_isa} ne 'auto')
                  )
            ) {
                $string .= (' ' x $p->{_current_indent})
                        . 'Linear @ISA   '
                        . join(', ', map { colored( $_, $p->{color}->{'class'}) }
                                  @{mro::get_linear_isa($ref)}
                        ) . $BREAK;
            }
        }

        $string .= _show_methods($ref, $p)
            if $p->{class}{show_methods} and $p->{class}{show_methods} ne 'none';

        if ( $p->{'class'}->{'internals'} ) {
            $string .= (' ' x $p->{_current_indent})
                    . 'internals: ';

            local $p->{_reftype} = Scalar::Util::reftype $item;
            $string .= _p($item, $p);
            $string .= $BREAK;
        }

        $p->{_current_indent} -= $p->{indent};
        $string .= (' ' x $p->{_current_indent}) . "}";
    }
    $p->{class}{_depth}--;

    return $string;
}



######################################
## Auxiliary (internal) subs
######################################

# All glory to Vincent Pit for coming up with this implementation,
# to Goro Fuji for Hash::FieldHash, and of course to Michael Schwern
# and his "Object::ID", whose code is copied almost verbatim below.
{
    fieldhash my %IDs;

    my $Last_ID = "a";
    sub _object_id {
        my $self = shift;

        # This is 15% faster than ||=
        return $IDs{$self} if exists $IDs{$self};
        return $IDs{$self} = ++$Last_ID;
    }
}


sub _show_methods {
    my ($ref, $p) = @_;

    my $string = '';
    my $methods = {
        public => [],
        private => [],
    };
    my $inherited = $p->{class}{inherited} || 'none';

    require B;

    my $methods_of = sub {
        my ($name) = @_;
        map {
            my $m;
            if ($_
                and $m = B::svref_2object($_)
                and $m->isa('B::CV')
                and not $m->GV->isa('B::Special')
            ) {
                [ $m->GV->STASH->NAME, $m->GV->NAME ]
            } else {
                ()
            }
        } values %{Package::Stash->new($name)->get_all_symbols('CODE')}
    };

    my %seen_method_name;

METHOD:
    foreach my $method (
        map $methods_of->($_), @{mro::get_linear_isa($ref)},
                               $p->{class}{universal} ? 'UNIVERSAL' : ()
    ) {
        my ($package_string, $method_string) = @$method;

        next METHOD if $seen_method_name{$method_string}++;

        my $type = substr($method_string, 0, 1) eq '_' ? 'private' : 'public';

        if ($package_string ne $ref) {
            next METHOD unless $inherited ne 'none'
                           and ($inherited eq 'all' or $type eq $inherited);
            $method_string .= ' (' . $package_string . ')';
        }

        push @{ $methods->{$type} }, $method_string;
    }

    # render our string doing a natural sort by method name
    my $show_methods = $p->{class}{show_methods};
    foreach my $type (qw(public private)) {
        next unless $show_methods eq 'all'
                 or $show_methods eq $type;

        my @list = ($p->{class}{sort_methods} ? nsort @{$methods->{$type}} : @{$methods->{$type}});

        $string .= (' ' x $p->{_current_indent})
                 . "$type methods (" . scalar @list . ')'
                 . (@list ? ' : ' : '')
                 . join(', ', map { colored($_, $p->{color}->{method}) }
                              @list
                   ) . $BREAK;
    }

    return $string;
}

sub _deparse {
    my ($item, $p) = @_;
    require B::Deparse;
    my $i = $p->{indent};
    my $deparseopts = ["-sCi${i}v'Useless const omitted'"];

    my $sub = 'sub ' . B::Deparse->new($deparseopts)->coderef2text($item);
    my $pad = "\n" . (' ' x ($p->{_current_indent} + $i));
    $sub    =~ s/\n/$pad/gse;
    return $sub;
}

sub _get_info_message {
    my $p = shift;
    my @caller = caller 2;

    my $message = $p->{caller_message};

    $message =~ s/\b__PACKAGE__\b/$caller[0]/g;
    $message =~ s/\b__FILENAME__\b/$caller[1]/g;
    $message =~ s/\b__LINE__\b/$caller[2]/g;

    return colored($message, $p->{color}{caller_info}) . $BREAK;
}


sub _merge {
    my $p = shift;
    my $clone = clone $properties;

    if ($p) {
        foreach my $key (keys %$p) {
            if ($key eq 'color' or $key eq 'colour') {
                my $color = $p->{$key};
                if ( not ref $color or ref $color ne 'HASH' ) {
                    Carp::carp q['color' should be a HASH reference. Did you mean 'colored'?];
                    $clone->{color} = {};
                }
                else {
                    foreach my $target ( keys %$color ) {
                        $clone->{color}->{$target} = $p->{$key}->{$target};
                    }
                }
            }
            elsif ($key eq 'class') {
                foreach my $item ( keys %{$p->{class}} ) {
                    $clone->{class}->{$item} = $p->{class}->{$item};
                }
            }
            elsif ($key eq 'filters') {
                my $val = $p->{$key};

                foreach my $item (keys %$val) {
                    my $filters = $val->{$item};

                    # EXPERIMENTAL: filters in modules
                    if ($item eq '-external') {
                        my @external = ( ref($filters) ? @$filters : ($filters) );

                        foreach my $class ( @external ) {
                            my $module = "Data::Printer::Filter::$class";
                            eval "use $module";
                            if ($@) {
                                warn "Error loading filter '$module': $@";
                            }
                            else {
                                my %from_module = %{$module->_filter_list};
                                my %extras      = %{$module->_extra_options};

                                foreach my $k (keys %from_module) {
                                    unshift @{ $clone->{filters}->{$k} }, @{ $from_module{$k} };
                                    $clone->{_seen_override}{$k} = 1
                                        if $extras{$k}{show_repeated};
                                }
                            }
                        }
                    }
                    else {
                        my @filter_list = ( ref $filters eq 'CODE' ? ( $filters ) : @$filters );
                        unshift @{ $clone->{filters}->{$item} }, @filter_list;
                    }
                }
            }
            elsif ($key eq 'output') {
                my $out = $p->{output};
                my $ref = ref $out;

                $clone->{output} = $out;

                my %output_target = (
                     stdout => *STDOUT,
                     stderr => *STDERR,
                );

                my $error;
                if (!$ref and exists $output_target{ lc $out }) {
                    $clone->{_output} = $output_target{ lc $out };
                }
                elsif ( ( $ref and $ref eq 'GLOB')
                     or (!$ref and \$out =~ /GLOB\([^()]+\)$/)
                ) {
                    $clone->{_output} = $out;
                }
                elsif ( !$ref or $ref eq 'SCALAR' ) {
                    if( open my $fh, '>>', $out ) {
                        $clone->{_output} = $fh;
                    }
                    else {
                        $error = 1;
                    }
                }
                else {
                    $error = 1;
                }

                if ($error) {
                    Carp::carp 'Error opening custom output handle.';
                    $clone->{_output} = $output_target{ 'stderr' };
                }
            }
            else {
                $clone->{$key} = $p->{$key};
            }
        }
    }

    return $clone;
}


sub _load_rc_file {
    my $args = shift || {};

    my $file = exists $args->{rc_file}    ? $args->{rc_file}
             : exists $ENV{DATAPRINTERRC} ? $ENV{DATAPRINTERRC}
             : File::Spec->catfile(File::HomeDir->my_home,'.dataprinter');

    return unless -e $file;

    my $mode = (stat $file )[2];
    if ($^O !~ /Win32/i && ($mode & 0020 || $mode & 0002) ) {
        warn "rc file '$file' must NOT be writeable to other users. Skipping.\n";
        return;
    }

    if ( -l $file || (!-f _) || -p _ || -S _ || -b _ || -c _ ) {
        warn "rc file '$file' doesn't look like a plain file. Skipping.\n";
        return;
    }

    unless (-o $file) {
        warn "rc file '$file' must be owned by your (effective) user. Skipping.\n";
        return;
    }

    if ( open my $fh, '<', $file ) {
        my $rc_data;
        { local $/; $rc_data = <$fh> }
        close $fh;

        if( ${^TAINT} != 0 ) {
            if ( $args->{allow_tainted} ) {
                warn "WARNING: Reading tainted file '$file' due to user override.\n";
                $rc_data =~ /(.+)/s; # very bad idea - god help you
                $rc_data = $1;
            }
            else {
                warn "taint mode on: skipping rc file '$file'.\n";
                return;
            }
        }

        my $config = eval $rc_data;
        if ( $@ ) {
            warn "Error loading $file: $@\n";
        }
        elsif (!ref $config or ref $config ne 'HASH') {
            warn "Error loading $file: config file must return a hash reference\n";
        }
        else {
            $properties = _merge( $config );
        }
    }
    else {
        warn "error opening '$file': $!\n";
    }
}


1;
__END__

=encoding utf8

=head1 NAME

Data::Printer - colored pretty-print of Perl data structures and objects

=head1 SYNOPSIS

Want to see what's inside a variable in a complete, colored
and human-friendly way?

  use Data::Printer;   # or just "use DDP" for short
  
  p @array;            # no need to pass references

Code above might output something like this (with colors!):

   [
       [0] "a",
       [1] "b",
       [2] undef,
       [3] "c",
   ]

You can also inspect objects:

    my $obj = SomeClass->new;

    p($obj);

Which might give you something like:

  \ SomeClass  {
      Parents       Moose::Object
      Linear @ISA   SomeClass, Moose::Object
      public methods (3) : bar, foo, meta
      private methods (0)
      internals: {
         _something => 42,
      }
  }

Data::Printer is fully customizable. If you want to change how things
are displayed, or even its standard behavior. Take a look at the
L<< available customizations|/"CUSTOMIZATION" >>. Once you figure out
your own preferences, create a
L<< configuration file|/"CONFIGURATION FILE (RUN CONTROL)" >> for
yourself and Data::Printer will automatically use it!

B<< That's about it! Feel free to stop reading now and start dumping
your data structures! For more information, including feature set,
how to create filters, and general tips, just keep reading :) >>

Oh, if you are just experimenting and/or don't want to use a
configuration file, you can set all options during initialization,
including coloring, identation and filters!

  use Data::Printer {
      color => {
         'regex' => 'blue',
         'hash'  => 'yellow',
      },
      filters => {
         'DateTime' => sub { $_[0]->ymd },
         'SCALAR'   => sub { "oh noes, I found a scalar! $_[0]" },
      },
  };

The first C<{}> block is just syntax sugar, you can safely ommit it
if it makes things easier to read:

  use DDP colored => 1;

  use Data::Printer  deparse => 1, sort_keys => 0;


=head1 FEATURES

Here's what Data::Printer has to offer to Perl developers, out of the box:

=over 4

=item * Very sane defaults (I hope!)

=item * Highly customizable (in case you disagree with me :)

=item * Colored output by default

=item * Human-friendly output, with array index and custom separators

=item * Full object dumps including methods, inheritance and internals

=item * Exposes extra information such as tainted data and weak references

=item * Ability to easily create filters for objects and regular structures

=item * Ability to load settings from a C<.dataprinter> file so you don't have to write anything other than "use DDP;" in your code!

=back

=head1 RATIONALE

Data::Dumper is a fantastic tool, meant to stringify data structures
in a way they are suitable for being C<eval>'ed back in.

The thing is, a lot of people keep using it (and similar ones,
like Data::Dump) to print data structures and objects on screen
for inspection and debugging, and while you B<can> use those
modules for that, it doesn't mean mean you B<should>.

This is where Data::Printer comes in. It is meant to do one thing
and one thing only:

I<< display Perl variables and objects on screen, properly
formatted >> (to be inspected by a human)

If you want to serialize/store/restore Perl data structures,
this module will NOT help you. Try L<Storable>, L<Data::Dumper>,
L<JSON>, or whatever. CPAN is full of such solutions!

=head1 THE p() FUNCTION

Once you load Data::Printer, the C<p()> function will be imported
into your namespace and available to you. It will pretty-print
into STDERR (or any other output target) whatever variabe you pass to it.

=head2 Changing output targets

By default, C<p()> will be set to use STDERR. As of version 0.27, you
can set up the 'output' property so Data::Printer outputs to
several different places:

=over 4

=item * C<< output => 'stderr' >> - Standard error. Same as *STDERR

=item * C<< output => 'stdout' >> - Standard output. Same as *STDOUT

=item * C<< output => $filename >> - Appends to filename.

=item * C<< output => $file_handle >> - Appends to opened handle

=item * C<< output => \$scalar >> - Appends to that variable's content

=back

=head2 Return Value

If for whatever reason you want to mangle with the output string
instead of printing it, you can simply ask for a return
value:

  # move to a string
  my $string = p @some_array;

  # output to STDOUT instead of STDERR;
  print p(%some_hash);

Note that, in this case, Data::Printer will not colorize the
returned string unless you explicitly set the C<colored> option to 1:

  print p(%some_hash, colored => 1); # now with colors!

You can - and should - of course, set this during you "C<use>" call:

  use Data::Printer colored => 1;
  print p( %some_hash );  # will be colored

Or by adding the setting to your C<.dataprinter> file.

As most of Data::Printer, the return value is also configurable. You
do this by setting the C<return_value> option. There are three options
available:

=over 4

=item * C<'dump'> (default):

    p %var;               # prints the dump to STDERR (void context)
    my $string = p %var;  # returns the dump *without* printing

=item * C<'void'>:

    p %var;               # prints the dump to STDERR, never returns.
    my $string = p %var;  # $string is undef. Data still printed in STDERR


=item * C<'pass'>:

    p %var;               # prints the dump to STDERR, returns %var
    my %copy = p %var;    # %copy = %var. Data still printed in STDERR

=back

=head1 COLORS AND COLORIZATION

Below are all the available colorizations and their default values.
Note that both spellings ('color' and 'colour') will work.

   use Data::Printer {
     color => {
        array       => 'bright_white',  # array index numbers
        number      => 'bright_blue',   # numbers
        string      => 'bright_yellow', # strings
        class       => 'bright_green',  # class names
        method      => 'bright_green',  # method names
        undef       => 'bright_red',    # the 'undef' value
        hash        => 'magenta',       # hash keys
        regex       => 'yellow',        # regular expressions
        code        => 'green',         # code references
        glob        => 'bright_cyan',   # globs (usually file handles)
        vstring     => 'bright_blue',   # version strings (v5.16.0, etc)
        repeated    => 'white on_red',  # references to seen values
        caller_info => 'bright_cyan',   # details on what's being printed
        weak        => 'cyan',          # weak references
        tainted     => 'red',           # tainted content
        escaped     => 'bright_red',    # escaped characters (\t, \n, etc)

        # potential new Perl datatypes, unknown to Data::Printer
        unknown     => 'bright_yellow on_blue',
     },
   };

Don't fancy colors? Disable them with:

  use Data::Printer colored => 0;

By default, 'colored' is set to C<"auto">, which means Data::Printer
will colorize only when not being used to return the dump string,
nor when the output (default: STDERR) is being piped. If you're not
seeing colors, try forcing it with:

  use Data::Printer colored => 1;

Also worth noticing that Data::Printer I<will> honor the
C<ANSI_COLORS_DISABLED> environment variable unless you force a
colored output by setting 'colored' to 1.

Remember to put your preferred settings in the C<.dataprinter> file
so you never have to type them at all!


=head1 ALIASING

Data::Printer provides the nice, short, C<p()> function to dump your
data structures and objects. In case you rather use a more explicit
name, already have a C<p()> function (why?) in your code and want
to avoid clashing, or are just used to other function names for that
purpose, you can easily rename it:

  use Data::Printer alias => 'Dumper';

  Dumper( %foo );


=head1 CUSTOMIZATION

I tried to provide sane defaults for Data::Printer, so you'll never have
to worry about anything other than typing C<< "p( $var )" >> in your code.
That said, and besides coloring and filtering, there are several other
customization options available, as shown below (with default values):

  use Data::Printer {
      name           => 'var',   # name to display on cyclic references
      indent         => 4,       # how many spaces in each indent
      hash_separator => '   ',   # what separates keys from values
      colored        => 'auto',  # colorize output (1 for always, 0 for never)
      index          => 1,       # display array indices
      multiline      => 1,       # display in multiple lines (see note below)
      max_depth      => 0,       # how deep to traverse the data (0 for all)
      sort_keys      => 1,       # sort hash keys
      deparse        => 0,       # use B::Deparse to expand (expose) subroutines
      show_tied      => 1,       # expose tied variables
      show_tainted   => 1,       # expose tainted variables
      show_weak      => 1,       # expose weak references
      show_readonly  => 0,       # expose scalar variables marked as read-only
      show_lvalue    => 1,       # expose lvalue types
      print_escapes  => 0,       # print non-printable chars as "\n", "\t", etc.
      quote_keys     => 'auto',  # quote hash keys (1 for always, 0 for never).
                                 # 'auto' will quote when key is empty/space-only.
      separator      => ',',     # uses ',' to separate array/hash elements
      end_separator  => 0,       # prints the separator after last element in array/hash.
                                 # the default is 0 that means not to print

      caller_info    => 0,       # include information on what's being printed
      use_prototypes => 1,       # allow p(%foo), but prevent anonymous data
      return_value   => 'dump',  # what should p() return? See 'Return Value' above.
      output         => 'stderr',# where to print the output. See
                                 # 'Changing output targets' above.

      class_method   => '_data_printer', # make classes aware of Data::Printer
                                         # and able to dump themselves.

      class => {
          internals  => 1,       # show internal data structures of classes

          inherited  => 'none',  # show inherited methods,
                                 # can also be 'all', 'private', or 'public'.

          universal  => 1,       # include UNIVERSAL methods in inheritance list

          parents    => 1,       # show parents, if there are any
          linear_isa => 'auto',  # show the entire @ISA, linearized, whenever
                                 # the object has more than one parent. Can
                                 # also be set to 1 (always show) or 0 (never).

          expand     => 1,       # how deep to traverse the object (in case
                                 # it contains other objects). Defaults to
                                 # 1, meaning expand only itself. Can be any
                                 # number, 0 for no class expansion, and 'all'
                                 # to expand everything.

          sort_methods => 1,     # sort public and private methods

          show_methods => 'all'  # method list. Also 'none', 'public', 'private'
      },
  };

Note: setting C<multiline> to C<0> will also set C<index> and C<indent> to C<0>.

=head1 FILTERS

Data::Printer offers you the ability to use filters to override
any kind of data display. The filters are placed on a hash,
where keys are the types - or class names - and values
are anonymous subs that receive two arguments: the item itself
as first parameter, and the properties hashref (in case your
filter wants to read from it). This lets you quickly override
the way Data::Printer handles and displays data types and, in
particular, objects.

  use Data::Printer filters => {
            'DateTime'      => sub { $_[0]->ymd },
            'HTTP::Request' => sub { $_[0]->uri },
  };

Perl types are named as C<ref> calls them: I<SCALAR>, I<ARRAY>,
I<HASH>, I<REF>, I<CODE>, I<Regexp> and I<GLOB>. As for objects,
just use the class' name, as shown above.

As of version 0.13, you may also use the '-class' filter, which
will be called for all non-perl types (objects).

Your filters are supposed to return a defined value (usually, the
string you want to print). If you don't, Data::Printer will
let the next filter of that same type have a go, or just fallback
to the defaults. You can also use an array reference to pass more
than one filter for the same type or class.

B<Note>: If you plan on calling C<p()> from I<within> an inline
filter, please make sure you are passing only REFERENCES as
arguments. See L</CAVEATS> below.

You may also like to specify standalone filter modules. Please
see L<Data::Printer::Filter> for further information on a more
powerful filter interface for Data::Printer, including useful
filters that are shipped as part of this distribution.

=head1 MAKING YOUR CLASSES DDP-AWARE (WITHOUT ADDING ANY DEPS)

Whenever printing the contents of a class, Data::Printer first
checks to see if that class implements a sub called '_data_printer'
(or whatever you set the "class_method" option to in your settings,
see L</CUSTOMIZATION> below).

If a sub with that exact name is available in the target object,
Data::Printer will use it to get the string to print instead of
making a regular class dump.

This means you could have the following in one of your classes:

  sub _data_printer {
      my ($self, $properties) = @_;
      return 'Hey, no peeking! But foo contains ' . $self->foo;
  }

Notice you don't have to depend on Data::Printer at all, just
write your sub and it will use that to pretty-print your objects.

If you want to use colors and filter helpers, and still not
add Data::Printer to your dependencies, remember you can import
them during runtime:

  sub _data_printer {
      require Data::Printer::Filter;
      Data::Printer::Filter->import;

      # now we have 'indent', outdent', 'linebreak', 'p' and 'colored'
      my ($self, $properties) = @_;
      ...
  }

Having a filter for that particular class will of course override
this setting.


=head1 CONFIGURATION FILE (RUN CONTROL)

Data::Printer tries to let you easily customize as much as possible
regarding the visualization of your data structures and objects.
But we don't want you to keep repeating yourself every time you
want to use it!

To avoid this, you can simply create a file called C<.dataprinter> in
your home directory (usually C</home/username> in Linux), and put
your configuration hash reference in there.

This way, instead of doing something like:

   use Data::Printer {
     colour => {
        array => 'bright_blue',
     },
     filters => {
         'Catalyst::Request' => sub {
             my $req = shift;
             return "Cookies: " . p($req->cookies)
         },
     },
   };

You can create a .dataprinter file that looks like this:

   {
     colour => {
        array => 'bright_blue',
     },
     filters => {
         'Catalyst::Request' => sub {
             my $req = shift;
             return "Cookies: " . p($req->cookies)
         },
     },
   };

Note that all we did was remove the "use Data::Printer" bit when
writing the C<.dataprinter> file. From then on all you have to do
while debugging scripts is:

  use Data::Printer;

and it will load your custom settings every time :)

=head2 Loading RC files in custom locations

If your RC file is somewhere other than C<.dataprinter> in your home
dir, you can load whichever file you want via the C<'rc_file'> parameter:

  use Data::Printer rc_file => '/path/to/my/rcfile.conf';

You can even set this to undef or to a non-existing file to disable your
RC file at will.

The RC file location can also be specified with the C<DATAPRINTERRC>
environment variable. Using C<rc_file> in code will override the environment
variable.

=head2 RC File Security

The C<.dataprinter> RC file is nothing but a Perl hash that
gets C<eval>'d back into the code. This means that whatever
is in your RC file B<WILL BE INTERPRETED BY PERL AT RUNTIME>.
This can be quite worrying if you're not the one in control
of the RC file.

For this reason, Data::Printer takes extra precaution before
loading the file:

=over 4

=item * The file has to be in your home directory unless you
specifically point elsewhere via the 'C<rc_file>' property or
the DATAPRINTERRC environment variable;

=item * The file B<must> be a plain file, never a symbolic
link, named pipe or socket;

=item * The file B<must> be owned by you (i.e. the effective
user id that ran the script using Data::Printer);

=item * The file B<must> be read-only for everyone but your user.
This usually means permissions C<0644>, C<0640> or C<0600> in
Unix-like systems. B<THIS IS NOT CHECKED IN WIN32>;

=item * The file will B<NOT> be loaded in Taint mode, unless
you specifically load Data::Printer with the 'allow_tainted'
option set to true. And even if you do that, Data::Printer
will still issue a warning before loading the file. But
seriously, don't do that.

=back

Failure to comply with the security rules above will result in
the RC file not being loaded (likely with a warning on what went
wrong).


=head1 THE "DDP" PACKAGE ALIAS

You're likely to add/remove Data::Printer from source code being
developed and debugged all the time, and typing it might feel too
long. Because of this, the 'DDP' package is provided as a shorter
alias to Data::Printer:

   use DDP;
   p %some_var;

=head1 CALLER INFORMATION

If you set caller_info to a true value, Data::Printer will prepend
every call with an informational message. For example:

  use Data::Printer caller_info => 1;

  my $var = 42;
  p $var;

will output something like:

  Printing in line 4 of myapp.pl:
  42

The default message is C<< 'Printing in line __LINE__ of __FILENAME__:' >>.
The special strings C<__LINE__>, C<__FILENAME__> and C<__PACKAGE__> will
be interpolated into their according value so you can customize them at will:

  use Data::Printer
    caller_info => 1,
    caller_message => "Okay, __PACKAGE__, let's dance!"
    color => {
        caller_info => 'bright_red',
    };

As shown above, you may also set a color for "caller_info" in your color
hash. Default is cyan.


=head1 EXPERIMENTAL FEATURES

The following are volatile parts of the API which are subject to
change at any given version. Use them at your own risk.

=head2 Local Configuration (experimental!)

You can override global configurations by writing them as the second
parameter for p(). For example:

  p( %var, color => { hash => 'green' } );


=head2 Filter classes

As of Data::Printer 0.11, you can create complex filters as a separate
module. Those can even be uploaded to CPAN and used by other people!
See L<Data::Printer::Filter> for further information.

=head1 CAVEATS

You can't pass more than one variable at a time.

   p($foo, $bar); # wrong
   p($foo);       # right
   p($bar);       # right

The default mode is to use prototypes, in which you are supposed to pass
variables, not anonymous structures:

   p( { foo => 'bar' } ); # wrong

   p %somehash;        # right
   p $hash_ref;        # also right

To pass anonymous structures, set "use_prototypes" option to 0. But
remember you'll have to pass your variables as references:

   use Data::Printer use_prototypes => 0;

   p( { foo => 'bar' } ); # was wrong, now is right.

   p( %foo  ); # was right, but fails without prototypes
   p( \%foo ); # do this instead

If you are using inline filters, and calling p() (or whatever name you
aliased it to) from inside those filters, you B<must> pass the arguments
to C<p()> as a reference:

  use Data::Printer {
      filters => {
          ARRAY => sub {
              my $listref = shift;
              my $string = '';
              foreach my $item (@$listref) {
                  $string .= p( \$item );      # p( $item ) will not work!
              }
              return $string;
          },
      },
  };

This happens because your filter function is compiled I<before> Data::Printer
itself loads, so the filter does not see the function prototype. As a way
to avoid unpleasant surprises, if you forget to pass a reference, Data::Printer
will generate an exception for you with the following message:

    'When calling p() without prototypes, please pass arguments as references'

Another way to avoid this is to use the much more complete L<Data::Printer::Filter>
interface for standalone filters.

=head1 EXTRA TIPS

=head2 Circumventing prototypes

The C<p()> function uses prototypes by default, allowing you to say:

  p %var;

instead of always having to pass references, like:

  p \%var;

There are cases, however, where you may want to pass anonymous
structures, like:

  p { foo => $bar };   # this blows up, don't use

and because of prototypes, you can't. If this is your case, just
set "use_prototypes" option to 0. Note, with this option,
you B<will> have to pass your variables as references:

  use Data::Printer use_prototypes => 0;

   p { foo => 'bar' }; # doesn't blow up anymore, works just fine.

   p %var;  # but now this blows up...
   p \%var; # ...so do this instead

   p [ $foo, $bar, \@baz ]; # this way you can even pass
                            # several variables at once

Versions prior to 0.17 don't have the "use_prototypes" option. If
you're stuck in an older version you can write C<&p()> instead of C<p()>
to circumvent prototypes and pass elements (including anonymous variables)
as B<REFERENCES>. This notation, however, requires enclosing parentheses:

  &p( { foo => $bar } );        # this is ok, use at will
  &p( \"DEBUGGING THIS BIT" );  # this works too

Or you could just create a very simple wrapper function:

  sub pp { p @_ };

And use it just as you use C<p()>.

=head2 Minding the return value of p()

I<< (contributed by Matt S. Trout (mst)) >>

There is a reason why explicit return statements are recommended unless
you know what you're doing. By default, Data::Printer's return value
depends on how it was called. When not in void context, it returns the
serialized form of the dump.

It's tempting to trust your own p() calls with that approach, but if
this is your I<last> statement in a function, you should keep in mind
your debugging code will behave differently depending on how your
function was called!

To prevent that, set the C<return_value> property to either 'void'
or 'pass'. You won't be able to retrieve the dumped string but, hey,
who does that anyway :)

Assuming you have set the pass-through ('pass') property in your
C<.dataprinter> file, another stunningly useful thing you can do with it
is change code that says:

   return $obj->foo;

with:

   use DDP;

   return p $obj->foo;

You can even add it to chained calls if you wish to see the dump of
a particular state, changing this:

   $obj->foo->bar->baz;

to:

   $obj->foo->DDP::p->bar->baz

And things will "Just Work".


=head2 Using p() in some/all of your loaded modules

I<< (contributed by Matt S. Trout (mst)) >>

While debugging your software, you may want to use Data::Printer in
some or all loaded modules and not bother having to load it in
each and every one of them. To do this, in any module loaded by
C<myapp.pl>, simply write:

  ::p( @myvar );  # note the '::' in front of p()

Then call your program like:

  perl -MDDP myapp.pl

This also has the great advantage that if you leave one p() call
in by accident, it will fail without the -M, making it easier to spot :)

If you really want to have p() imported into your loaded
modules, use the next tip instead.

=head2 Adding p() to all your loaded modules

I<< (contributed by Árpád Szász) >>

If you wish to automatically add Data::Printer's C<p()> function to
every loaded module in you app, you can do something like this to
your main program:

    BEGIN {
        {
            no strict 'refs';
            require Data::Printer;
            my $alias = 'p';
            foreach my $package ( keys %main:: ) {
                if ( $package =~ m/::$/ ) {
                    *{ $package . $alias } = \&Data::Printer::p;
                }
            }
        }
    }

B<WARNING> This will override all locally defined subroutines/methods that
are named C<p>, if they exist, in every loaded module. If you already
have a subroutine named 'C<p()>', be sure to change C<$alias> to
something custom.

If you rather avoid namespace manipulation altogether, use the previous
tip instead.

=head2 Using Data::Printer from the Perl debugger

I<< (contributed by Árpád Szász and Marcel Grünauer (hanekomu)) >>

With L<DB::Pluggable>, you can easily set the perl debugger to use
Data::Printer to print variable information, replacing the debugger's
standard C<p()> function. All you have to do is add these lines to
your C<.perldb> file:

  use DB::Pluggable;
  DB::Pluggable->run_with_config( \'[DataPrinter]' );  # note the '\'

Then call the perl debugger as you normally would:

  perl -d myapp.pl

Now Data::Printer's C<p()> command will be used instead of the debugger's!

See L<perldebug> for more information on how to use the perl debugger, and
L<DB::Pluggable> for extra functionality and other plugins.

If you can't or don't wish to use DB::Pluggable, or simply want to keep
the debugger's C<p()> function and add an extended version using
Data::Printer (let's call it C<px()> for instance), you can add these
lines to your C<.perldb> file instead:

    $DB::alias{px} = 's/px/DB::px/';
    sub px {
        my $expr = shift;
        require Data::Printer;
        print Data::Printer::p($expr);
    }

Now, inside the Perl debugger, you can pass as reference to C<px> expressions
to be dumped using Data::Printer.

=head2 Using Data::Printer in a perl shell (REPL)

Some people really enjoy using a REPL shell to quickly try Perl code. One
of the most famous ones out there is L<Devel::REPL>. If you use it, now
you can also see its output with Data::Printer!

Just install L<Devel::REPL::Plugin::DataPrinter> and add the following
line to your re.pl configuration file (usually ".re.pl/repl.rc" in your
home dir):

  load_plugin('DataPrinter');

The next time you run C<re.pl>, it should dump all your REPL using
Data::Printer!

=head2 Easily rendering Data::Printer's output as HTML

To turn Data::Printer's output into HTML, you can do something like:

  use HTML::FromANSI;
  use Data::Printer;
  
  my $html_output = ansi2html( p($object, colored => 1) );

In the example above, the C<$html_output> variable contains the
HTML escaped output of C<p($object)>, so you can print it for
later inspection or render it (if it's a web app).

=head2 Using Data::Printer with Template Toolkit

I<< (contributed by Stephen Thirlwall (sdt)) >>

If you use Template Toolkit and want to dump your variables using Data::Printer,
install the L<Template::Plugin::DataPrinter> module and load it in your template:

   [% USE DataPrinter %]

The provided methods match those of C<Template::Plugin::Dumper>:

   ansi-colored dump of the data structure in "myvar":
   [% DataPrinter.dump( myvar ) %]

   html-formatted, colored dump of the same data structure:
   [% DataPrinter.dump_html( myvar ) %]

The module allows several customization options, even letting you load it as a
complete drop-in replacement for Template::Plugin::Dumper so you don't even have
to change your previous templates!

=head2 Unified interface for Data::Printer and other debug formatters

I<< (contributed by Kevin McGrath (catlgrep)) >>

If you are porting your code to use Data::Printer instead of
Data::Dumper or similar, you can just replace:

  use Data::Dumper;

with:

  use Data::Printer alias => 'Dumper';
  # use Data::Dumper;

making sure to provide Data::Printer with the proper alias for the
previous dumping function.

If, however, you want a really unified approach where you can easily
flip between debugging outputs, use L<Any::Renderer> and its plugins,
like L<Any::Renderer::Data::Printer>.

=head2 Printing stack traces with arguments expanded using Data::Printer

I<< (contributed by Sergey Aleynikov (randir)) >>

There are times where viewing the current state of a variable is not
enough, and you want/need to see a full stack trace of a function call.

The L<Devel::PrettyTrace> module uses Data::Printer to provide you just
that. It exports a C<bt()> function that pretty-prints detailed information
on each function in your stack, making it easier to spot any issues!

=head2 Troubleshooting apps in real time without changing a single line of your code

I<< (contributed by Marcel Grünauer (hanekomu)) >>

L<dip> is a dynamic instrumentation framework for troubleshooting Perl
programs, similar to L<DTrace|http://opensolaris.org/os/community/dtrace/>.
In a nutshell, C<dip> lets you create probes for certain conditions
in your application that, once met, will perform a specific action. Since
it uses Aspect-oriented programming, it's very lightweight and you only
pay for what you use.

C<dip> can be very useful since it allows you to debug your software
without changing a single line of your original code. And Data::Printer
comes bundled with it, so you can use the C<p()> function to view your
data structures too!

   # Print a stack trace every time the name is changed,
   # except when reading from the database.
   dip -e 'before { print longmess(p $_->{args}[1]) if $_->{args}[1] }
     call "MyObj::name" & !cflow("MyObj::read")' myapp.pl

You can check you L<dip>'s own documentation for more information and options.

=head2 Sample output for color fine-tuning

I<< (contributed by Yanick Champoux (yanick)) >>

The "examples/try_me.pl" file included in this distribution has a sample
dump with a complex data structure to let you quickly test color schemes.

=head2 creating fiddling filters

I<< (contributed by dirk) >>

Sometimes, you may want to take advantage of Data::Printer's original dump,
but add/change some of the original data to enhance your debugging ability.
Say, for example, you have an C<HTTP::Response> object you want to print
but the content is encoded. The basic approach, of course, would be to
just dump the decoded content:

  use DDP filter {
    'HTTP::Response' => sub { p( \shift->decoded_content, %{shift} );
  };

But what if you want to see the rest of the original object? Dumping it
would be a no-go, because you would just recurse forever in your own filter.

Never fear! When you create a filter in Data::Printer, you're not replacing
the original one, you're just stacking yours on top of it. To forward your data
to the original filter, all you have to do is return an undefined value. This
means you can rewrite your C<HTTP::Response> filter like so, if you want:

  use DDP filters => {
    'HTTP::Response' => sub {
      my ($res, $p) = @_;

      # been here before? Switch to original handler
      return if exists $res->{decoded_content};

      # first timer? Come on in!
      my $clone = $res->clone;
      $clone->{decoded_content} = $clone->decoded_content;
      return p($clone, %$p);
    }
  };

And voilà! Your fiddling filter now works like a charm :)

=head1 BUGS

If you find any, please file a bug report.


=head1 SEE ALSO

L<Data::Dumper>

L<Data::Dump>

L<Data::Dumper::Concise>

L<Data::Dump::Streamer>

L<Data::PrettyPrintObjects>

L<Data::TreeDumper>


=head1 AUTHOR

Breno G. de Oliveira C<< <garu at cpan.org> >>

=head1 CONTRIBUTORS

Many thanks to everyone that helped design and develop this module
with patches, bug reports, wishlists, comments and tests. They are
(alphabetically):

=over 4

=item * Allan Whiteford

=item * Andreas König

=item * Andy Bach

=item * Árpád Szász

=item * brian d foy

=item * Chris Prather (perigrin)

=item * David Golden (xdg)

=item * David Raab

=item * Damien Krotkine (dams)

=item * Denis Howe

=item * Dotan Dimet

=item * Eden Cardim (edenc)

=item * Elliot Shank (elliotjs)

=item * Fernando Corrêa (SmokeMachine)

=item * Fitz Elliott

=item * Ivan Bessarabov (bessarabv)

=item * J Mash

=item * Jesse Luehrs (doy)

=item * Joel Berger (jberger)

=item * Kartik Thakore (kthakore)

=item * Kevin Dawson (bowtie)

=item * Kevin McGrath (catlgrep)

=item * Kip Hampton (ubu)

=item * Marcel Grünauer (hanekomu)

=item * Matt S. Trout (mst)

=item * Maxim Vuets

=item * Mike Doherty (doherty)

=item * Paul Evans (LeoNerd)

=item * Przemysław Wesołek (jest)

=item * Rebecca Turner (iarna)

=item * Rob Hoelz (hoelzro)

=item * Sebastian Willing (Sewi)

=item * Sergey Aleynikov (randir)

=item * Stanislaw Pusep (syp)

=item * Stephen Thirlwall (sdt)

=item * sugyan

=item * Tatsuhiko Miyagawa (miyagawa)

=item * Tim Heaney (oylenshpeegul)

=item * Torsten Raudssus (Getty)

=item * Wesley Dal`Col (blabos)

=item * Yanick Champoux (yanick)

=back

If I missed your name, please drop me a line!


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Breno G. de Oliveira C<< <garu at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.



=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.



