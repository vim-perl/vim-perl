package Data::Printer::Filter::DB;
use strict;
use warnings;
use Data::Printer::Filter;
use Term::ANSIColor;

filter 'DBI::db', sub {
    my ($dbh, $p) = @_;
    my $name = $dbh->{Driver}{Name};

    my $string = "$name Database Handle ("
               . ($dbh->{Active} 
                  ? colored('connected', 'bright_green')
                  : colored('disconnected', 'bright_red'))
               . ') {'
               ;
    indent;
    my %dsn = split( /[;=]/, $dbh->{Name} );
    foreach my $k (keys %dsn) {
        $string .= newline . "$k: " . $dsn{$k};
    }
    $string .= newline . 'Auto Commit: ' . $dbh->{AutoCommit};

    my $kids = $dbh->{Kids};
    $string .= newline . 'Statement Handles: ' . $kids;
    if ($kids > 0) {
        $string .= ' (' . $dbh->{ActiveKids} . ' active)';
    }

    if ( defined $dbh->err ) {
        $string .= newline . 'Error: ' . $dbh->errstr;
    }
    $string .= newline . 'Last Statement: '
            . colored( ($dbh->{Statement} || '-'), 'bright_yellow');

    outdent;
    $string .= newline . '}';
    return $string;
};

filter 'DBI::st', sub {
    my ($sth, $properties) = @_;
    my $str = colored( ($sth->{Statement} || '-'), 'bright_yellow');

    if ($sth->{NUM_OF_PARAMS} > 0) {
        my $values = $sth->{ParamValues};
        if ($values) {
            $str .= '  (' 
                 . join(', ',
                      map {
                         my $v = $values->{$_};
                         $v || 'undef';
                      } 1 .. $sth->{NUM_OF_PARAMS}
                   )
                 . ')';
        }
        else {
            $str .= colored('  (bindings unavailable)', 'yellow');
        }
    }
    return $str;
};

# DBIx::Class filters
filter '-class' => sub {
    my ($obj, $properties) = @_;

    if ( $obj->isa('DBIx::Class::Schema') ) {
        return ref($obj) . ' DBIC Schema with ' . p( $obj->storage->dbh );
    }
    elsif ( grep { $obj->isa($_) } qw(DBIx::Class::ResultSet DBIx::Class::ResultSetColumn) ) {

        my $str = colored( ref($obj), $properties->{color}{class} );
        $str .= ' (' . $obj->result_class . ')'
          if $obj->can( 'result_class' );

        if (my $query_data = $obj->as_query) {
          my @query_data = @$$query_data;
          indent;
          my $sql = shift @query_data;
          $str .= ' {'
               . newline . colored($sql, 'bright_yellow')
               . newline . join ( newline, map {
                      $_->[1] . ' (' . $_->[0]{sqlt_datatype} . ')'
                    } @query_data
               )
               ;
          outdent;
          $str .= newline . '}';
        }

        return $str;
    }
    else {
        return;
    }
};


1;
__END__

=head1 NAME

Data::Printer::Filter::DB - pretty printing database objects


=head1 SYNOPSIS

In your program:

  use Data::Printer filters => {
      -external => [ 'DB' ],
  };

or, in your C<.dataprinter> file:

  {
    filters => {
      -external => [ 'DB' ],
    },
  };



=head1 DESCRIPTION

This is a filter plugin for L<Data::Printer>. It filters through
L<DBI>'s handlers (dbh) and statement (sth) objects displaying relevant
information for the user.

L<DBI> is an extremely powerful and complete database interface. But
it does a lot of magic under the hood, making their objects somewhat harder
to debug. This filter aims to fix that :)

For instance, say you want to debug something like this:

  use DBI;
  my $dbh = DBI->connect('dbi:DBM(RaiseError=1):', undef, undef );

A regular Data::Dumper output gives you absolutely nothing:

$VAR1 = bless( {}, 'DBI::db' );

L<Data::Printer> makes it better, but only to debug the class itself,
not helpful at all to see its contents and debug your own code:

    DBI::db  {
        Parents       DBI::common
        Linear @ISA   DBI::db, DBI::common
        public methods (48) : begin_work, clone, column_info, commit, connected, data_sources, disconnect, do, foreign_key_info, get_info, last_insert_id, ping, prepare, prepare_cached, preparse, primary_key, primary_key_info, quote, quote_identifier, rollback, rows, selectall_arrayref, selectall_hashref, selectcol_arrayref, selectrow_array, selectrow_arrayref, selectrow_hashref, sqlite_backup_from_file, sqlite_backup_to_file, sqlite_busy_timeout, sqlite_collation_needed, sqlite_commit_hook, sqlite_create_aggregate, sqlite_create_collation, sqlite_create_function, sqlite_enable_load_extension, sqlite_last_insert_rowid, sqlite_progress_handler, sqlite_register_fts3_perl_tokenizer, sqlite_rollback_hook, sqlite_set_authorizer, sqlite_update_hook, statistics_info, table_info, tables, take_imp_data, type_info, type_info_all
        private methods (0)
        internals: {
        }
    }

Fear no more! If you use this filter, here's what you'll see:

    SQLite Database Handle (connected) {
        dbname: file.db
        Auto Commit: 1
        Statement Handles: 0
        Last Statement: -
    }

Much better, huh? :)

Statement handlers are even better. Imagine you continued your code with something like:

  my $sth = $dbh->prepare('SELECT * FROM foo WHERE bar = ?');
  $sth->execute(42);

With this filter, instead of an empty dump or full method information, you'll get
exactly what you came for:

 SELECT * FROM foo WHERE bar = ?  (42)

Note that if your driver does not support holding of parameter values, you'll get a
C<bindings unavailable> message instead of the bound values.


=head1 SEE ALSO

L<Data::Printer>


