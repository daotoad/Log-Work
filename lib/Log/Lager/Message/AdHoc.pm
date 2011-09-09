package Log::Lager::Message::AdHoc;
BEGIN {
  $Log::Lager::Message::AdHoc::VERSION = '0.02';
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

sub message {
    my $self = shift;

my $message = [
        { adhoc => $self->{message} || []  },
    ]
}

1;
