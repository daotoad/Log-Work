package Log::Work::SimpleLager;
{
  $Log::Work::SimpleLager::VERSION = '0.02.03';
}
use strict;
use warnings;

require Log::Lager;
require Log::Work;
require Log::Lager::Message::Work;
require Log::Lager::Message::AdHoc;

our $ALREADY_LOADED = 0;

sub import {
    my $class = shift;
    my $package = caller();

    # Pass arguments to Log::Work
    my $log_work_args  = join ', ', map "'$_'", @_;

    my $already_loaded = $ALREADY_LOADED++;

    # Only set the Log::Lager object the first time we are loaded.
    my $log_lager_args = $already_loaded
                       ? ''
                       : "'message Log::Lager::Message::AdHoc'";

    my $register_handlers = $already_loaded
                          ? ''
                          : <<"END_CODE";

Log::Work->on_finish( sub { Log::Lager::Message::Work->new( \@_ ) } )
    if Log::Work->has_default_on_finish;

Log::Work->on_error( sub { Log::Lager::ERROR(\@_) } )
    if Log::Work->has_default_on_error;

END_CODE

    my $code = <<"END_CODE";
package $package;

use Log::Lager $log_lager_args;

use Log::Work $log_work_args;
$register_handlers

1;

END_CODE

    eval $code or die $@;

    return 1;

}

1;

__END__

=head1 NAME

Log::Work::SimpleLager - Make it easier to use Log::Work with Log::Lager

=head1 VERSION

version 0.02.03

=head1 SYNOPSIS

    use Log::Work::SimpleLager ':standard';

    # only needed in an executable not in a library:
    use Log::Work::ProvenanceId 'Foo.Bar';

    INFO "Emit an ad hoc log message";

    TRACE WORK {
        # Do some stuff.

        RESULT_NORMAL;

    } 'Some Task';

=head1 DESCRIPTION

Log::Work::SimpleLager is exists to simplify the use of Log::Lager and Log::Work together.  It is entirely possible to use these two systems together without using Log::Work::SimpleLager.

When used, Log::Lager does a few simple things:

=over

=item *

Load Log::Lager and export its subroutines.

=item *

If this is the first time Log::Work::SimpleLager is loaded, it will set Log::Lager's default message object to Log::Lager::Message::AdHoc

=item *

Load Log::Work

Any arguments to the use line are passed to Log::Work's use line.

=item *

If this is the first time Log::Work::SimpleLager is loaded AND the default C<on_finish> is currently selected, it registers an C<on_finish> handler with Log::Work that generates Log::Lager::Message::Work objects.

=item *

If this is the first time Log::Work::SimpleLager is loaded AND the default C<on_error> is currently selected, it registers an C<on_error> handler with Log::Work that emits an ad hoc ERROR level message using Log::Lager.

=back

See the source code for more details.

=head1 CREDITS

Written by Mark Swayne for Marchex.
Contributions from Alex Popiel and Tye McQueen.

Thank you to Marchex for allowing me to share this work.
