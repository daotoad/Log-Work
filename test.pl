
use strict;
use warnings;

use Log::Lager qw( FEWIDTG );
use Log::Work;

use Log::ProvenanceId 'FU.B234';

TRACE  qw( starting up now ) ;

INFO WORK {

     DEBUG "Beginning to do something.";

    INFO REMOTE {
        DEBUG "Remote ca ca";
        TRACE "Set inner result";
        RESULT_NORMAL;

    } 'Inner'; 

    TRACE "Set outer result";
    RESULT_NORMAL;
} 'Outer';


TRACE "All Done";

