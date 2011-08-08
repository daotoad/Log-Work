use strict;
use warnings;

use Log::Lager qw( FEWIDTG  stack FEWITDG pretty FEWITDG );
use Log::Work qw(add_metric RESULT_NORMAL RESULT_FAILURE);
use Log::Lager::Work;

Log::Work->on_finish( 'Log::Lager::Work', 'new' );
Log::Work->on_error( sub { ERROR @_ } );

use Log::ProvenanceId 'FU.B234';

use constant UNITS => 5;
use constant CHANCE => 100;


# Start 5 units of work that will count to 10
my @units = map Log::Work->start(dumb_name(6)), 1..UNITS;

while( @units ) {

    my $index = int rand @units;

    my $u = $units[$index];

    my $result;
    eval {
        $result = $u->step( \&worker);
        1;
    }
    or do {
        my $e = $@;
        $u->RESULT_EXCEPTION
        unless $u->has_result;
        $u->record_value( exception => $e );

        goto DONE;
    };

    next unless $result;

DONE:
    INFO  $u->finish;
    splice @units, $index, 1;
}


sub worker {
    my $rand = int rand CHANCE;

    add_metric( 'callcount', 1, 'iterations' );

    die "I feel sick\n" if $rand == CHANCE-1;

    RESULT_FAILURE if $rand == int( CHANCE / 2 );

    return $rand == 0;
}



sub dumb_name {
    my $length = shift;

    my @alphabet = (
         ('a') x 8, ('b') x 1, ('c') x 2, ('d') x 4,
         ('e') x 1, ('f') x 2, ('g') x 2, ('h') x 6,
         ('i') x 6, ('j') x 1, ('k') x 1, ('l') x 4,
         ('m') x 2, ('n') x 6, ('o') x 7, ('p') x 1, 
         ('q') x 1, ('r') x 5, ('s') x 6, ('t') x 9,
         ('u') x 2, ('v') x 1, ('w') x 2, ('x') x 1, 
         ('y') x 1, ('z') x 1,
    );
    use List::Util qw(shuffle);

    my @name = shuffle @alphabet;
    return join '', @name[0..$length];
}
