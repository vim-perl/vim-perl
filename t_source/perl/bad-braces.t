push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );

my %hash = map { $_->{class}->id } @{$specs_flattened->{$set}} );

my $hashref = { map { $_->{class}->id } @{$specs_flattened->{$set}} ) };

for my $i ( 1..10 ) {
    push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );
}

sub foo {
    push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );
}

if ( foo() ) {
    push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );
}
elsif ( bar() ) {
    push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );
}
else {
    push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );
}

my @flrids = join( ' ', map { $_->{flrid} } @{$set} );

my $set = sqldo_set( $sql, { ':listid' => $listid } );

if ( @{$set} > 1_000 ) {
    # Do nothing
}
else {
    my $flrids = join( ' ', map { $_->{flrid} } @{$set} );
    return "flrid:($flrids)";
}


MAIN: {
    while ( <> ) {
        if ( $line =~ m{^INFO:.+/select params=\{(.+)\} hits=(\d+) status=0 QTime=(\d+)} ) {
            # do something
        }
    }
}

$foo =~ s{ /$}{};

my $listref = [ map { {$_ => 9} } @foo ];

my $foo = {
    blah => x,
    foo => x,
};

my $x =
{
    yada,
    yada,
};
