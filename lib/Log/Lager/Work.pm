package Log::Lager::Work;
use strict;
use warnings;

use Log::Work qw( :simple );

use Time::HiRes qw( time );
use Scalar::Util qw(weaken blessed );

use Exporter qw( import );
our @EXPORT = qw( EVENT REMOTE WORK );
our @EXPORT_OK = qw(
        WORK REMOTE EVENT

        RESULT_NORMAL         RESULT_INVALID
        RESULT_EXCEPTION      RESULT_FAILURE

        record_value
        add_metric
        set_accumulator
);
our %EXPORT_TAGS = (
        simple        => [qw( WORK
                              EVENT
                              RESULT_NORMAL    RESULT_INVALID
                              RESULT_EXCEPTION RESULT_FAILURE
                         )],
        metadata      => [qw( add_metric record_value set_accumulator set_result )],
        values        => [qw( record_value )],
        metrics       => [qw( add_metric )],
        accumulators  => [qw( set_accumulator inherit_accumulator )],
);

our @ISA = 'Log::Work';


sub finish {
    my $self = shift;

    return Log::Lager::TypedMessage->new(UnitofWork => $self->SUPER::finish(@_) );
}

# ----------------------------------------------------------
#   High level interface methods
# ----------------------------------------------------------


# ----------------------------------------------------------
#  Task methods
# ----------------------------------------------------------

1;
