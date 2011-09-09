package Log::Lager::Message::Work;
use strict;
use warnings;

use Log::Work qw( :simple );
use Log::Lager::Message;


our @ISA = 'Log::Lager::Message';

sub register_standard_handlers {
    Log::Work->on_finish( sub { Log::Lager::Message::Work->new(@_) } );
    Log::Work->on_error(  sub { Log::Lager::ERROR(@_)     } );
}

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

    $self->SUPER::_init( context => 1, message => [], want_bits => 1, @_ );
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
        { uow => {
                start    => $self->{start_time},
                end      => $self->{end_time},
                duration => $self->{duration} * 1000,
                result   => $self->{result},
                metrics  => $self->{metrics}, 
                values   => $self->{values},
            }
        },
    ];

    return $message;
}

=head1 NAME

Log::Lager::Work

1;
