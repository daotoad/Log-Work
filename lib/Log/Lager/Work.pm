package Log::Lager::Work;
use strict;
use warnings;

require Log::Lager;
require Log::Work;
require Log::Lager::Message::Work;
require Log::Lager::Message::AdHoc;

sub import {
    my $class = shift;
    my $package = caller();

    # Pass arguments to Log::Work
    my $log_work_args  = join ', ', map "'$_'", @_;

    # Only set the Log::Lager object the first time we are loaded.
    my $log_lager_args = exists $INC{'Log/Lager/Work.pm'} 
                       ? ''
                       : "'message Log::Lager::Message::AdHoc'";


    my $code = <<"END_CODE";
package $package;

use Log::Work $log_work_args;

Log::Work->on_finish( sub { Log::Lager::Message::Work->new( \@_ ) } );
Log::Work->on_error( sub { Log::Lager::ERROR(\@_) } );

use Log::Lager $log_lager_args;

1;

END_CODE

     return 1;

}

1;

__END__

=head1 NAME

Log::Lager::Work - Make it easier to use Log::Work with Log::Lager

=head1 SYNOPSIS

    use Log::Lager::Work ':standard';

    # only needed in an executable not in a library:
    use ProvenanceId 'Foo.Bar';

    INFO "Emit an ad hoc log message";

    TRACE WORK {
        # Do some stuff.

        RESULT_NORMAL;

    } 'Some Task';

=head1 DESCRIPTION

Log::Lager::Work is exists to simplify the use of Log::Lager and Log::Work together.  It is entirely possible to use these two systems together without using Log::Lager::Work.

When used, Log::Lager does a few simple things:

=over

=item *

Load Log::Lager and export its subroutines.

=item *

If this is the first time Log::Lager::Work is loaded, it will set Log::Lager's default message object to Log::Lager::Message::AdHoc

=item *

Load Log::Work

Any arguments to the use line are passed to Log::Work's use line.

=item *

Registers an C<on_finish> handler with Log::Work that generates Log::Lager::Message::Work objects.

=item *

Registers an C<on_error> handler with Log::Work that emits an ad hoc ERROR level message using Log::Lager.

=back

See the source code for more details.

=head1 CREDITS

Written by Mark Swayne for Marchex.
Contributions from Alex Popiel and Tye McQueen.

Thank you to Marchex for allowing me to share this work.

