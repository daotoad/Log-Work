
use strict;
use warnings;

use Log::Lager qw( FEWIDTG );
use Log::Work::SimpleLager ':standard';


use Log::Work::ProvenanceId 'FU.B234';


TRACE  qw( starting up now ) ;

INFO WORK {

    DEBUG "Beginning to do something.", $Log::Work::CURRENT_UNIT;

    INFO WORK {
        TRACE "Set inner result", $Log::Work::CURRENT_UNIT;
        die "Bella Lugosi is dead.";
        RESULT_NORMAL;

    } 'Inner';

    TRACE "Set outer result", $Log::Work::CURRENT_UNIT;
    RESULT_NORMAL;
} 'Outer';


TRACE "All Done", $Log::Work::CURRENT_UNIT;

