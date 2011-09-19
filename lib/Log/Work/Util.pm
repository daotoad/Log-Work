package Log::Work::Util;
BEGIN {
  $Log::Work::Util::VERSION = '0.03.01';
}

use strict;
use warnings;

use Scalar::Util qw< reftype >;

use Exporter qw< import >;

our @EXPORT_OK = qw(
        first_external_package
        _set_handler
    );

sub first_external_package {
    my $base_frame = shift || 0;
    my $skip_regex = shift || qr/^Log::(?:Work|Event)/x;

    $base_frame++;

    my $package = 'invalid namespace';

    while( my $new_pkg = caller($base_frame) ) {
        if( $new_pkg =~ /$skip_regex/ ) {
            $base_frame++;
            next;
        }
        else {
            $package = $new_pkg;
            last;
        }
    }

    return $package;
}

sub _set_handler {
    my $target  = shift;
    my $default = shift;

    if( @_ == 1 ) {
        my $coderef = shift;
        return unless defined $coderef;

        $$target = $coderef eq 'DEFAULT'      ?  $default
                 : reftype $coderef eq 'CODE' ? $coderef
                 : $$target;
    }
    elsif( @_ == 2 ) {
        my ( $class, $method ) = @_;
        my $resolved = $class->can($method);

        return unless $resolved;
        $$target = sub{ $class->$method(@_) };
    }

    return;
}
