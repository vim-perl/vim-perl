use strict;
use warnings;

sub extract_date {
    my ( $table_name ) = @_;

    my ( $year, $month, $day ) = $table_name =~ /(\d{4})(\d{2})(\d{2})$/;
    return join('-', $year, $month, $day);
}
