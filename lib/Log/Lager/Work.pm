package Log::Lager::Work;
use strict;
use warnings;

use Log::Work qw( :simple );
use Log::Lager::Message;


our @ISA = 'Log::Lager::Message';


sub _init {
    my $self = shift;
    my $work = shift;

    $self->{provenance_id} = $work->{id};
    $self->{type} = "UOW";

    $self->{$_} = $work->{$_} 
        for qw(
            id
            start_time
            end_time
            duration
            status
            metrics
            values
            accumulator
            result_code
            namespace
            name
            result
        );

    $self->SUPER::_init( context => 1, message => [], @_ );
}


sub _header {
    my $self = shift;

    my @header = map $self->{$_}, qw(
        timestamp
        type
        loglevel
        hostname
        executable
        process_id
        thread_id
        id
        namespace
        name
    );

    return \@header;
}

sub message {
    my $self = shift;

    my $message = [
        { ouw => {
                start    => $self->{start_time},
                end      => $self->{end_time},
                duration => $self->{duration} * 1000,
                result   => $self->{result},
                metrics  => $self->{metrics}, 
                values   => $self->{values},
            }
        }
    ];

    return $message;
}


1;
