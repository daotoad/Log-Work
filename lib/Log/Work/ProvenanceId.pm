package Log::Work::ProvenanceId;
{
  $Log::Work::ProvenanceId::VERSION = '0.02.03';
}

use strict;
use warnings;

use Carp qw(croak);
use Sys::Hostname;
use Socket;

our @CARP_NOT = qw( Log::Work Log::Lager Log::Lager::Message );

my $IDBASE;
my $IP;
my $TIME;
my $RAND;
my $COUNTER = 0;

my $RX_STRICT_PRODUCT_IDENTIFIER = qr/[A-Za-z]\w*/;
my $RX_STRICT_SERVICE_IDENTIFIER = $RX_STRICT_PRODUCT_IDENTIFIER;
my $RX_STRICT_UNIQUEIFIER        = qr/[^:,\s]+/;

my $RX_STRICT_VALID_BASE = qr{

    $RX_STRICT_PRODUCT_IDENTIFIER
    \.
    $RX_STRICT_SERVICE_IDENTIFIER

}x;

my $RX_STRICT_VALID_ROOT = qr{
    $RX_STRICT_VALID_BASE
    \.
    $RX_STRICT_UNIQUEIFIER
    :                 # ID terminator
}x;

my $RX_STRICT_VALID_ID = qr{

    $RX_STRICT_VALID_ROOT

    (                 # Virtual call trace
        \d+r?         #  Initial request identifier
        (,\d+r?)*     #  Additional request identifiers
    )?
}x;


sub import {
    my $class = shift;
    my $newbase = shift;

    return unless defined $newbase;

    croak "The base value for the Provenance ID has already been set"
        if (
            defined $IDBASE
        and $IDBASE ne $newbase
        );

    croak "The base value '$newbase' for the Provenance ID is invalid"
        unless is_valid_base_prov_id( $newbase );
    $IDBASE = $newbase;

    return 1;
}

sub new_root_id {
    my $base = shift;
    $base = $IDBASE unless defined $base;

    croak "No base ID specified for this application"
        unless defined $base;

    $IP = _get_ip()
        unless defined $IP;
    $TIME = time
        unless defined $TIME;
    $RAND = rand( 10000)
        unless defined $RAND;

    return sprintf "%s.%s.%0d.%10d.%04d.%0d:",
        $base, $IP, $$, $TIME, $RAND, $COUNTER++,

}


sub _get_ip {
    my $host = hostname;
    my $ip = inet_aton hostname;
    $ip = inet_ntoa $ip
        if defined $ip;

    $ip = join '', map sprintf("%02X",$_), split /[.]/, $ip;

}

sub is_valid_prov_id {
    my $pvid = shift;
    return unless defined $pvid;

    return $pvid =~ /^$RX_STRICT_VALID_ID$/;
}

sub is_valid_base_prov_id {
    my $base = shift;
    return unless defined $base;

    return $base =~ /^$RX_STRICT_VALID_BASE$/;
}

sub is_valid_root_prov_id {
    my $pvid = shift;
    return unless defined $pvid;

    return $pvid =~ /^$RX_STRICT_VALID_ROOT$/;
}


sub is_local {
    return ! is_remote(@_);
}

sub is_remote {
    my $id = shift;
    return unless defined $id;

    my $di = reverse $id;

    return $di =~ /^r\d+[^:]*:/;
}

sub get_parent_id {
    my $id = shift;

    my ($root,$trace) = $id =~ /^([^:]*:)(.*)/;

    return unless length $trace;

    my @trace = ( split /,/, $trace);

    pop @trace;

    return  $root . join ',', @trace;

}


1;

__END__

=head1 NAME

Log::Work::ProvenanceId

=head1 VERSION

version 0.02.03

=head1 SYNOPSIS


    # Set a provenance id for a whole script:
    use Log::Work::ProvenanceId 'Wub.Wub';

    # Load LWPID and mess with provenance ids:
    use Log::Work::ProvenanceId;

    if( is_valid_base_prov_id( 'Foo.Bar') ) {
        # Do something
    }

=head1 DESCRIPTION


=head2 Structure of a Provenance ID

PROV_ID           = ROOT_ID REQUEST_ID
                    /  PROV_ID "," REQUEST_ID
BASE              = PRODUCT_ID "." SERVICE_ID
ROOT              = BASE "." UNIQUIFIER ":"
REQUEST_ID        = LOCAL_REQUEST_ID / REMOTE_REQUEST_ID
LOCAL_REQUEST_ID  = DIGIT
REMOTE_REQUEST_ID = \d+r


=head2 Custom Import Semantics

=head2 Subroutines

=head3 new_root_id

=head3 is_valid_prov_id

=head3 is_valid_base_prov_id

=head3 is_valid_root_prov_id

=head3 is_local

=head3 is_remote


=head1 CREDITS

Written by Mark Swayne for Marchex.
Contributions from Alex Popiel and Tye McQueen.

Thank you to Marchex for allowing me to share this work.
