@new_array = map { $hash{$_} } @array; # dsfdsfsdfds
sub foo {
    {
        print {$foo} @new_array;
    }
}
print {FOOBAR} @new_array;

map { { bar => $hash{$_} } } @keys;
push @{$foo->{bar}}, $elem;
say for keys %{$foo->{bar}};
sub foo {
    print @{$bar->{x}};
}

sub foo {
    push( @ids, map { $_->{class}->id } @{$specs_flattened->{$set}} );
}

print join("," map { "$_=h{$_}" } keys %h);

print join("," map { "$_=h$_}" } keys %h);
