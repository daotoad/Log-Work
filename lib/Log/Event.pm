package Log::Event;
# ABSTRACT:  Break tasks into labeld units of work that are trackable across hosts and helper systems.

use strict;
use warnings;

use Log::Work::Util  qw< first_external_package _set_handler >;
use Log::ProvenanceId;

use Time::HiRes qw( time );
use Scalar::Util qw(weaken blessed );

use Exporter qw( import );

our @EXPORT_OK = qw( EVENT );
our @EXPORT    = qw( EVENT );

our $DEFAULT_ON_FINISH = sub { return shift };
our $ON_FINISH = $DEFAULT_ON_FINISH;


{    # Attribute Setup

    my @ATTRIBUTES = qw(
            id
            name
            namespace
            time
            kvp
        );
    my %ATTRIBUTES = map { $_ => undef } @ATTRIBUTES;

    sub new {
        my $class = shift;
        my %arg   = @_;

        my $self = bless {}, $class;
        $self->{$_} = $arg{$_} for keys %ATTRIBUTES;

        return $self;
    }
};

sub on_finish {
    shift; # Remove invocant
    _set_handler( \$ON_FINISH, $DEFAULT_ON_FINISH, @_ );
    return;
}

sub init {
    my $class = shift;
    my $kvp   = shift;

    my $pvid = $Log::Work::CURRENT_UNIT ? $Log::Work::CURRENT_UNIT->{id} : undef;

    my $package = first_external_package();

    my $self = $class->new(
        id          => $pvid,
        name        => 'EVENT',
        namespace   => $package,
        kvp         => $kvp,
        'time'      => time(),
    );

    return $self;
}


sub EVENT (@) {
    my %kvp;
    if( @_ == 1 ) {
        my $arg = shift;

        no warnings 'uninitialized';
        # Yes, ref - if an object is passed here it should be treated as a message.
        %kvp = ref($arg) eq 'HASH' ? (%$arg) : ( message => $arg );
    }
    else {
        $kvp{message} = \@_;
    }

    my $ev = __PACKAGE__->init( \%kvp );
    return $ON_FINISH->($ev);
}


1;
