package Log::Lager::Event;
use strict;
use warnings;

use Log::Event;
use Log::Lager::Message;


our @ISA = 'Log::Lager::Message';

sub register_standard_handlers {
    Log::Event->on_finish( sub { Log::Lager::Event->new( @_ ) } );
}

sub _init {
    my $self = shift;
    my $event = shift;

    $self->{provenance_id} = $event->{id};
    $self->{type} = "EVENT";

    $self->{$_} = $event->{$_} 
        for qw(
            id
            namespace
            name
            kvp
        );

    $self->SUPER::_init( context => 1, message => [], want_bits => 1, timestamp => $event->{time}, @_ );
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
        { event => $self->{kvp}          }
    ];

    return $message;
}


1;
