
use strict;
use warnings;

use Log::Lager qw( FEWIDTG  pretty FEWIDTG );
use Log::Work;
use Log::Lager::Work;


use Log::ProvenanceId 'FU.B234';

Log::Work->on_finish( 'Log::Lager::Work', 'new' );
Log::Work->on_error( sub { ERROR @_ } );

TRACE  qw( starting up now ) ;

INFO WORK {

     DEBUG "Beginning to do something.", $Log::Work::CURRENT_UNIT;

    INFO REMOTE {
        DEBUG "Remote ca ca";
        TRACE "Set inner result", $Log::Work::CURRENT_UNIT;
        RESULT_NORMAL;

    } 'Inner'; 

    TRACE "Set outer result", $Log::Work::CURRENT_UNIT;
    RESULT_NORMAL;
} 'Outer';


TRACE "All Done", $Log::Work::CURRENT_UNIT;

