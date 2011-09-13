package Log::Lager::Message::AdHoc;
BEGIN {
  $Log::Lager::Message::AdHoc::VERSION = '0.02.02';
}
use strict;
use warnings;

use Log::Lager::Message;
our @ISA = 'Log::Lager::Message';

use Log::Work::Util qw< first_external_package >;

sub _init {
    my $self = shift;

    my $cu = Log::Work->current_unit;

    $self->{provenance_id} = $cu->{id};
    $self->{type} = "ADHOC";
    $self->{name} = "AdHoc";
    $self->{namespace} = first_external_package(2, qr/^Log::(?:Work|Event|Lager)/x );
    $self->SUPER::_init( context => 1, want_bits => 1, @_ );
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
        provenance_id
        namespace
        name
    );

    return \@header;
}

sub message {    my $self = shift;
my $message = [
        { adhoc => $self->{message} || []  },
    ]
}

1;

__END__

=head1 NAME

Log::Lager::Message::AdHoc - A Log::Lager::Message object for use with Log::Lager.

=head1 VERSION

version 0.02.02

=head1 SYNOPSIS

    use Log::Lager;
    use Log::Work ':simple';
    use Log::Lager::Message::AdHoc;

    # Register Log::Lager::Message::AdHoc as the standard message object for Log::Lager
    use Log::Lager 'message Log::Lager::Message::AdHoc';

    # or register using apply command:
    Log::Lager->apply_command( 'message Log::Lager::Message::AdHoc' );

    INFO 'Blah blah blah';

=head1 DESCRIPTION

This is a subclass of Log::Lager::Message that is used to record ad hoc logging data in a format this is compatible with Log::Work.  The role of this class is to provide a compatible behaviors between Log::Work and ad hoc messages generated with Log::Lager.

=head1 SEE ALSO

Log::Lager - Provide easy to use, lexically controllable logging in JSON format.

Log::Work - Track program tasks with a structured unique ID.

Log::Lager::Message - Base class for all Log::Lager::Message objects.

Log::Lager::Message::Work - Another LLM subclass for combining Log::Lager with the Log::Work suite.

=head1 CREDITS

Written by Mark Swayne for Marchex.
Contributions from Alex Popiel and Tye McQueen.

Thank you to Marchex for allowing me to share this work.
