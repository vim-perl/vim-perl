
# These all look OK

push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );

my %hash = map { $_->{class}->id } @{$specs_flattened->{$set}} );

my $hashref = { map { $_->{class}->id } @{$specs_flattened->{$set}} ) };

for my $i ( 1..10 ) {
    push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );
}


# For Andy, this is not colored right
sub foo {
    push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );
}

