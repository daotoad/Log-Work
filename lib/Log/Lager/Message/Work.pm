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
            result_code
            namespace
            name
            result
            return_values
            return_exception
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

1;

__END__

=head1 NAME

Log::Lager::Message::Work - A Log::Lager::Message object for use with Log::Lager.

=head1 SYNOPSIS

    use Log::Lager;
    use Log::Work ':simple';
    use Log::Lager::Message::Work;

    # Register standard Log::Work Handlers
    Log::Lager::Message::Work->register_standard_handlers();

    # or register them manually:
    Log::Work->on_finish( Log::Lager::Message::Work => 'new' );
    Log::Work->on_error( sub { Log::Lager::ERROR( @_ ) } );

    INFO WORK {
        # Do some stuff here.
    } 'Some Job';

=head1 DESCRIPTION

This is a subclass of Log::Lager::Message that is used to record information about a Log::Work object.  The role of this class is to act as a translation layer between the two different systems.

=head1 SEE ALSO

Log::Lager - Provide easy to use, lexically controllable logging in JSON format.

Log::Work - Track program tasks with a structured unique ID.

Log::Lager::Message - Base class for all Log::Lager::Message objects.

Log::Lager::Message::AdHoc - Another LLM subclass for combining Log::Lager ad hoc logging with Log::Work suite.

=head1 CREDITS

Written by Mark Swayne for Marchex.
Contributions from Alex Popiel and Tye McQueen.

Thank you to Marchex for allowing me to share this work.

