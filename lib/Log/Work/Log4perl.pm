package Log::Work::Log4perl;
use strict;
use warnings;
use feature ':5.10';

use Log::Work;
use Date::Format qw(time2str);
use Time::HiRes 'time';
use JSON::XS ();

use Log::Log4perl 1.27 (); # for wrapper_register()
use Log::Log4perl::Level; # log constants
use base 'Log::Log4perl::Layout::PatternLayout';

our @skip_packages = qw(
    Log::Work
    Log::Work::Log4perl
    Log::Log4perl::Logger
    Log::Log4perl::Appender
);

Log::Log4perl->wrapper_register($_) for @skip_packages;

our $ALREADY_LOADED = 0;

sub import {
    my $class = shift;
    my $package = caller();

    return if $ALREADY_LOADED++;

    Log::Work->on_finish( \&_on_finish ) if ( Log::Work->has_default_on_finish );
    Log::Work->on_error(  \&_on_finish ) if ( Log::Work->has_default_on_error );

    return 1;
}

sub new {
    my $class = shift;
    $class = ref ($class) || $class;

    my $options       = ref $_[0] eq "HASH" ? shift : {};
    my $layout_string = '[["%X{time}","%X{type}","%p","%H","%X{program}",%P,"%X{threadid}","%X{contextid}","%C","%X{name}"],' .
        '{"%X{logtype}":{%m},"file":"%F","method":"%M","line":%L}]%n';

    $class->SUPER::new($options, $layout_string);
}

# most of this is taken care of for you by just using Log::Work,
# but you may want to add "program" to your $logwork object, else $0
# will be used.

sub render {
    my($self, $message, $category, $priority, $caller_level) = @_; # Log4perl object

    my $logwork = Log::Work->get_current_unit || {};

    my $type = $logwork->{type} || 'EVENT';
    my $program = $logwork->{program};
    if (!$program) {
        ($program = $0) =~ s/^.*?([^\/]+)$/$1/;
    }

    # we generate the time instead of using log4perl ("%d{yyyy-MM-dd}T%d{HH:mm:ss.SSSZ}")
    # because i want it in GMT and can't find a way to do that in log4perl
    Log::Log4perl::MDC->put('time',         _time_to_iso8601(time()));
    Log::Log4perl::MDC->put('type',         $type);
    Log::Log4perl::MDC->put('program',      $program);
    Log::Log4perl::MDC->put('threadid',     'main');
    Log::Log4perl::MDC->put('contextid',    $logwork->{id} || '-');
    Log::Log4perl::MDC->put('name',         $logwork->{name} || lc($type));

    if ($type eq 'UOW') {
        Log::Log4perl::MDC->put('logtype', 'uow');
        $message = _format_uow($logwork);
    }
    else {
        Log::Log4perl::MDC->put('logtype', 'event');
        $message = _format_event($logwork, $message);
    }

    $self->SUPER::render($message, $category, $priority, $caller_level);
}

sub _format_uow {
    my($self) = @_; # Log::Work object
    my $uow = {
        uow => {
            start       => _time_to_iso8601($self->{start_time}),
            end         => _time_to_iso8601($self->{end_time}),
            duration    => $self->{duration_ms},
            result      => $self->{result}
        }
    };

    $uow->{uow}{metrics}    = $self->{metrics} if keys %{$self->{metrics}};
    $uow->{uow}{values}     = $self->{values}  if keys %{$self->{values}};

    return _format_json(uow => $uow);
}

sub _format_event {
    my($self, $message) = @_; # Log::Work object
    (my $msg = $message) =~ s/\n/\|/g;
    my $event = {
        event => {
            message => $msg
        }
    };

    $event->{event}{values} = $self->{values}  if keys %{$self->{values}};

    return _format_json(event => $event);
}

sub _format_json {
    my($key, $data, $no_strip) = @_;

    my($value) = $data->{$key};
    return unless $value;

    my $formatted = JSON::XS::encode_json($value);
    unless ($no_strip) {
        $formatted =~ s/^{//;
        $formatted =~ s/}$//;
    }
    return $formatted;
}


sub _time_to_iso8601 {
    my($time) = @_;

    return if !defined($time) || !length($time) || $time =~ /[^\d\.]/;

    my $ms;
    if ($time =~ s/(\.\d+)$//) {
        $ms = sprintf '%03d', ($1 * 1000);
    }

    my $str = time2str("%Y-%m-%dT%H:%M:%SZ", $time, 'GMT');
    $str =~ s/Z$/.${ms}Z/ if $ms;
    return $str;
}


sub _on_finish {
    my($self) = @_;

    my $logger = $self->get_stash('log4perl_logger');
    return unless $logger;

    $self->{type} = 'UOW';

    my $log_level = $self->get_stash('log4perl_level');
    if (!$log_level) {
        for ( $self->{result} ) {
            when ('EXCEPTION') { $log_level = $FATAL }
            when ('FAILURE')   { $log_level = $WARN  }
            when ('INVALID')   { $log_level = $WARN  }
            default            { $log_level = $INFO  }
        }
    }

    $logger->log( $log_level );
}

sub _on_error {
    my($message, @args) = @_;
    my $self = pop @args;

    # this shouldn't happen
    if (!$self) {
        require Data::Dumper;
        warn Data::Dumper::Dumper(\@_);
        return;
    }

    my $logger = $self->get_stash('log4perl_logger');
    return unless $logger;

    $self->{type} = 'EVENT';

    my $log_level = $self->get_stash('log4perl_level');
    if (!$log_level) {
        for ($self->{result}) {
            when ('EXCEPTION') { $log_level = $FATAL }
            default            { $log_level = $ERROR }
        }
    }

    $logger->log( $log_level, $message );
}

1;

__END__

=head1 NAME

Log::Work::Log4perl - Make it easier to use Log::Work with Log::Log4perl

=head1 SYNOPSIS

    use Log::Log4perl;
    use Log::Work;
    use Log::Work::Log4perl;

    # only needed in an executable not in a library:
    use Log::Work::ProvenanceId 'Foo.Bar';

    # in logger conf:
    # log4perl.appender.FOO.layout=Log::Work::Log4perl
    Log::Log4perl->init($conf);
    my $logger = Log::Log4perl->get_logger();

    $logger->info("emit ad hoc log message");

    WORK {
        # set vars to use inside on_ handlers
        my $work = Log::Work->get_current_unit;
        $work->set_stash(log4perl_logger => $logger);

        # optional: will be set based on result if left undefined
        $work->set_stash(log4perl_level => $Log::Log4perl::INFO);

        # Do some stuff.

        RESULT_NORMAL;

    } 'Some Task';

=head1 DESCRIPTION

Log::Work::Log4perl exists to simplify the use of Log::Log4perl and Log::Work together.  It is entirely possible to use these two systems together without using Log::Work::Log4perl.

Log::Work::Log4perl does a few simple things:

=over

=item *

Works as a Log4perl Layout class and handles EVENT/UOW formatting

=item *

If this is the first time Log::Work::Log4perl is loaded AND the default C<on_finish> is currently selected, it registers an C<on_finish> handler with Log::Work.

=item *

If this is the first time Log::Work::Log4perl is loaded AND the default C<on_error> is currently selected, it registers an C<on_error> handler with Log::Work.

=back

See the source code for more details.


=head1 CREDITS

Written by Chris Nandor for Marchex, based on Log::Work by Mark Swayne, with Alex Popiel and Tye McQueen.

Thank you to Marchex for allowing me to share this work.
