use strict;
use warnings;

use Log::Lager qw( FEWIDTG );
use Log::Work qw(add_metric RESULT_NORMAL RESULT_FAILURE);

use Log::ProvenanceId 'FU.B234';

use constant UNITS => 5;
use constant CHANCE => 100;

use Log::Lager 'I';

# Start 5 units of work that will count to 10

my @units = map Log::Work->start, 1..UNITS;

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



