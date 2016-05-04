use Test::More tests => 6;
our $HAVE_LAGER;
our $LAGER_MESSAGE;


BEGIN {
    eval {
        require Log::Lager;
        $HAVE_LAGER = 1;
        $LAGER_MESSAGE = 'Log::Lager is loaded';
        1;
    } or do {
        $HAVE_LAGER = 0;
        $LAGER_MESSAGE = "$@";
    };
}

use_ok( 'Log::Work::ProvenanceId' );
use_ok( 'Log::Work::Util' );
use_ok( 'Log::Work' );

SKIP: {
    if( $HAVE_LAGER ) {
        note( $LAGER_MESSAGE );
    } else {
        diag( "Attempting to load Log::Lager...\n", $LAGER_MESSAGE );
        skip "Log::Lager not available", 3;
    }

    use_ok( 'Log::Lager::Message::Work' );
    use_ok( 'Log::Lager::Message::AdHoc' );
    use_ok( 'Log::Work::SimpleLager' );
}
