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

    my $log_work_args = join ', ', map "'$_'", @_;

    eval <<"END_CODE" or die $@;
package $package;
use Log::Lager 'message Log::Lager::Message::AdHoc';
use Log::Work $log_work_args;

Log::Work->on_finish( sub { Log::Lager::Message::Work->new( \@_ ) } );
Log::Work->on_error( sub { Log::Lager::ERROR(\@_) } );

1;

END_CODE

     return 1;

}

1;
