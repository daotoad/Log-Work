package Log::ProvenanceId;

use strict;
use warnings;

use Carp qw(croak);
use Sys::Hostname;
use Socket;

my $IDBASE;
my $IP;
my $TIME;
my $RAND;
my $COUNTER = 0;

my $RX_STRICT_PRODUCT_IDENTIFIER = qr/[A-Za-z][\w-]*/;
my $RX_STRICT_SERVICE_IDENTIFIER = $RX_STRICT_PRODUCT_IDENTIFIER;
my $RX_STRICT_UNIQUEIFIER        = qr/[^:.,\s]+/;

my $RX_STRICT_VALID_BASE = qr{

    $RX_STRICT_PRODUCT_IDENTIFIER
    \.
    $RX_STRICT_SERVICE_IDENTIFIER

}x;

my $RX_STRICT_VALID_ID = qr{

    $RX_STRICT_VALID_BASE
    \.
    $RX_STRICT_UNIQUEIFIER

    :                 # ID terminator

    (                 # Virtual call trace
        \d+r?         #  Initial element
        (,\d+r?)*     #  Additional
    )?
};


sub import {
    my $class = shift;
    my $newbase = shift;

    return unless defined $newbase;

    croak "The base value for the Provenance ID has already been set"
        if defined $IDBASE;

    croak "The base value '$newbase' for the Provenance ID is invalid"
        unless is_valid_base_prov_id( $newbase );
    $IDBASE = $newbase;

    return 1;
}

sub new_root_id {
    my $base = shift;
    $base = $IDBASE unless defined $base;

    croak "No base ID specified for this application.\n"
        unless defined $base;

    $IP = _get_ip()
        unless defined $IP;
    $TIME = time
        unless defined $TIME;
    $RAND = rand( 10000)
        unless defined $RAND;

    return sprintf "%s-%s-%0d-%10d-%04d-%0d:",
        $base, $IP, $$, $TIME, $RAND, $COUNTER++,

}


sub _get_ip {
    my $host = hostname;
    my $ip = inet_aton hostname;
    $ip = inet_ntoa $ip if defined $ip;

    $ip = join '', map sprintf("%02X",$_), split /[.]/, $ip;

}

sub is_valid_prov_id {
    my $pvid = shift;

    return $pvid =~ /$RX_STRICT_VALID_ID/;
}

sub is_valid_base_prov_id {
    my $base = shift;

    return $base =~ /$RX_STRICT_VALID_BASE/;
}

1;
