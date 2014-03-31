=head1 NAME

Log::Work::Log4perl::Simple - Setup for Log::Work::Log4perl

=head1 SYNOPSIS

    my $work = Log::Work::Log4perl::Simple->start($log4perl_logger, "some name");
    # ... do stuff
    $work->add_metric($metric_name, $metric_value, $metric_unit);
    $work->record_value($name, $value);
    $work->finish;

=head1 DESCRIPTION

This is a subclass of Log::Work, so you can find out more about how to use this
by looking at the object-oriented/manual interface there.

You also need Log::Work::Log4perl, and in your conf, set the "layout" to
"Log::Work::Log4perl".

C<on_finish> and C<on_error> handlers are set to call Log4perl itself.

The provenance ID root is set to 'test.test' by default.

The result is set to C<NORMAL> by default.

=cut

package Log::Work::Log4perl::Simple;

use warnings;
use strict;
use feature ':5.10';

use Log::Log4perl 1.27 (); # for wrapper_register()
use Log::Log4perl::Level; # log constants
use Log::Work::Log4perl ();
use Scalar::Util 'blessed';

use base 'Log::Work';

our $CONSOLE_WORK = {
    'log4perl.rootLogger'                   => 'INFO, STDERR',
    'log4perl.appender.STDERR'              => 'Log::Log4perl::Appender::Screen',
    'log4perl.appender.STDERR.layout'       => 'Log::Work::Log4perl',
};

Log::Log4perl->wrapper_register(__PACKAGE__);

our @UNITS;

sub start {
    my($pkg, $logger, $name, $pvid_in, $alt_base) = @_;

    if (blessed($pkg)) {
        die "Can't call start() as an object method";
    }

    $logger   ||= $CONSOLE_WORK;
    $alt_base ||= 'test.test';
    $pvid_in  ||= undef;

    my $self = $pkg->SUPER::start($name, $pvid_in, $alt_base);

    # save the logger object for use in the layout class
    $self->set_stash(log4perl_logger => $logger);

    # maybe already loaded, but just in case
    $self->on_finish( \&Log::Work::Log4perl::_on_finish );
    $self->on_error(  \&Log::Work::Log4perl::_on_error );

    push @UNITS, $self;

    return $self;
}

# when we create a UOW, we push them onto @UNITS.  then we can see the most recently
# added UOW by checking its tail.  we then try to remove it when we finish(),
# and skip it in get_work() if it has been finished and didn't get removed.
sub finish {
    my($self) = @_;

    $self->RESULT_NORMAL() unless $self->has_result;
    my $return = $self->SUPER::finish;

    my @units;
    for my $u (@UNITS) {
        # keep the unit if it exists, and it has an ID, and its ID is not our ID
        push @units, $u if $u && ref($u) && $u->{id} && $u->{id} ne $self->{id};
    }
    @UNITS = @units;

    return $return;
}

sub get_work {
    # return most recently created unit ...
    for my $idx (reverse(0..$#UNITS)) {
        # ... unless it's been finished
        return $UNITS[$idx] unless $UNITS[$idx]->is_finished;
    }
    return;
}

"won't get fooled again";
