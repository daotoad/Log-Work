package Log::Work;
use strict;
use warnings;

use Log::Lager;
use Log::Lager::Work;
use Log::ProvenanceId;

use Time::HiRes qw( time );
use Scalar::Util qw(weaken blessed );

use Exporter qw( import );
our @EXPORT_OK = qw(
        WORK REMOTE

        RESULT_NORMAL
        RESULT_INVALID
        RESULT_EXCEPTION
        RESULT_FAILURE

        record_value
        add_metric
        set_accumulator

        new_child_id
        new_remote_id
);
our @EXPORT = qw(
        WORK
        REMOTE
        RESULT_NORMAL
        RESULT_INVALID
        RESULT_EXCEPTION
        RESULT_FAILURE
);

our %EXPORT_TAGS = (
        simple    => [qw( WORK
                          REMOTE
                          RESULT_NORMAL
                          RESULT_INVALID
                          RESULT_EXCEPTION
                          RESULT_FAILURE
                     )],
        new_ids   => [qw( new_child_id
                          new_remote_id 
                     )],
        metadata  => [qw( add_metric
                          record_value 
                          set_accumulator
                          set_result
                     )],
        standard  => [qw( :simple :metadata :new_ids )],
);

# Keep track of the current unit of work.
# This is intentionally a package variable as it will be
# managed via dynamic scoping using local().
our $CURRENT_UNIT = undef;

{    # Attribute Setup

    my @ATTRIBUTES = qw(
            parent      children
            id          counter
            name        namespace
            start_time  end_time
            finished    duration
            result      result_code
            metrics     accumulator
            values
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

# Special attribute accessors
sub _children {
    my $self = shift;

    $self->{children}  = {}
        unless $self->{children};

    return $self->{children};
}

sub _metrics {
    my $self = shift;

    $self->{metrics} = {}
        unless $self->{metrics};

    return $self->{metrics};
}

sub _values {
    my $self = shift;

    $self->{values} = {}
        unless $self->{values};

    return $self->{values};
}

sub _add_child {
    my $self = shift;
    my $child = shift;

    my $children = $self->_children;
    my $key = $child->{id};

    $children->{$key} = $child;
    weaken $self->{child}{$key};

    return $self;
}

sub _get_children {
    my $self = shift;

    my $children = $self->_children;

    return grep $_, values %$children;
}

sub get_values {
    my $self  = shift;
    return %{ $self->_values };
}


sub get_metrics {
    my $self  = shift;
    return %{ $self->{metrics} || {} };
}

# ----------------------------------------------------------
#   Low level interface methods
# ----------------------------------------------------------

sub start {
    my $class = shift;
    my $name  = shift;

    my $pvid = @_            ? shift 
             : $CURRENT_UNIT ? $CURRENT_UNIT->new_child_id
             : Log::ProvenanceId::new_root_id;

    my $package = caller;
    $package = caller(2)
        if $package eq $class or $package eq __PACKAGE__;

    my $self = $class->new(
        parent      => $CURRENT_UNIT,
        children    => {},   # Store weak kid refs so that they go away when kids are dead.

        id          => $pvid,
        name        => $name,
        namespace   => $package,

        start_time  => time,
        end_time    => undef,
        result      => undef,
        finished    => undef,

        metrics     => {},
        values      => {},
        accumulator => {},
        counter     => 0,   # First child is 1, next is 2, etc, regardless of internal/external.
    );

    $CURRENT_UNIT->_add_child($self) if $CURRENT_UNIT;

    return $self;
}



sub step {
    my $self = shift;
    my $code = shift;

    local $CURRENT_UNIT = $self;

    return $code->();
}

sub finish {
    my $self = shift;

    unless( eval { $self->isa('Log::Work') } ) {
        ERROR "Invalid Work specified for finish", $self;
        $self = Log::Work->new(
            parent      => 'INVALID',
            children    => {}, 
            id          => 'INVALID',
            name        => 'INVALID',
            package     =>  'INVALID',

            start_time  => time,
            end_time    => undef,
            result      => undef,
            finished    => undef,

            metrics     => {},
            values      => {},
            accumulator => {},
        );
    }

    if( $self->{finished} ) {
        ERROR 'Attempt to log previously finished Work', $self;
        $self->RESULT_INVALID 
    }

    my @children = $self->_get_children;
    $_->finish for grep defined, @children;

    $self->{end_time} = time;
    $self->{duration} = $self->{end_time} - $self->{start_time};

    $self->RESULT_INVALID
        unless $self->has_result;

    my %work;
    @work{qw/ start_time end_time duration status metrics values accumulator result_code /}
       = @{$self}{qw/ start_time end_time duration status metrics values accumulator result_code/};

    $self->{finish} = 1;

    return Log::Lager::Work->new( $self );
}

sub current_unit { $CURRENT_UNIT }

# ----------------------------------------------------------
#   High level interface methods
# ----------------------------------------------------------

sub WORK (&$;$) {
    my $code = shift;
    my $u = __PACKAGE__->start(@_);

    local $@;
    eval {
       $u->step( $code );
    }
    or do {
        my $e = $@;
        $u->RESULT_EXCEPTION
            unless $u->has_result;
        $u->record_value( exception => $e );
    };

    return $u->finish;
}

sub REMOTE (&$;$) {
    my $code = shift;
    my $name = shift;
    my $pvid = @_            ? shift 
             : $CURRENT_UNIT ? $CURRENT_UNIT->new_remote_id
             : Log::ProvenanceId::new_root_id;

    my $u = __PACKAGE__->start(@_);

    local $@;
    eval {
       $u->step( $code );
    }
    or do {
        my $e = $@;
        $u->RESULT_EXCEPTION
            unless $u->has_result;
        $u->record_value( exception => $e );
    };

    return $u->finish;
}




sub RESULT_INVALID   () { set_result('INVALID');   }
sub RESULT_EXCEPTION () { set_result('EXCEPTION'); }
sub RESULT_FAILURE   () { set_result('FAILURE');   }
sub RESULT_NORMAL    () { set_result('NORMAL');    }

# ----------------------------------------------------------
#  Task methods
# ----------------------------------------------------------

sub new_child_id {
    my $self = @_ ? shift : $CURRENT_UNIT;

    unless( eval { $self->isa( 'Log::Work' ); } ) {
        # ERROR 'Invalid unit of work specified.';
        return Log::ProvenanceId::new_root_id();
    }

    $self->{counter}++;

    my $id = sprintf "%s,%s",
        $self->{id}, $self->{counter};

    return $id;
}

sub new_remote_id {
    my $self = @_ ? shift : $CURRENT_UNIT;

    unless( eval { $self->isa( 'Log::Work' ); } ) {
        # ERROR 'Invalid unit of work specified.';
        return Log::ProvenanceId::new_root_id();
    }

    $self->{counter}++;

    my $id = sprintf "%s,%sr",
        $self->{id}, $self->{counter};

    return $id;
}


sub record_value {
    my $self   = blessed $_[0] ? shift : $CURRENT_UNIT;
    my $name  = shift;
    my $value = shift;

    my $values = $self->_values;

    if( exists $values->{$name} ) {
        $self->step(sub {
            #ERROR EVENT "OH SHIT - That value is already set!", $name, $values->{$name};
        });
    }

    $values->{$name} = $value;

    return $self;
}


sub add_metric {
    my $self   = blessed $_[0] ? shift : $CURRENT_UNIT;
    my $name   = shift;
    my $amount = shift;
    my $unit   = shift;

    # Get the metric hash ref and be sure that it is stored in the object.
    my $metrics = $self->_metrics;

    my $metric = $metrics->{$name};
    $metric = $metrics->{$name} = {}
        unless $metric;

    # Make sure units haven't changed.
    if( defined $metric->{unit}
            and
        defined $unit
            and
        $unit ne $metric->{unit}
    ) {
        $self->step(sub {
            #ERROR "OH SHIT - That metric has a different unit";
        });
        return $self;
    }

    # Finally adjust the metric
    $metric->{count}++;
    $metric->{total} += $amount;
    $metric->{unit}   = $unit 
        if defined $unit;

    return $self;
}


# Purposely allow non-specified values here.
sub set_result {
    my $self = blessed $_[0] ? shift : $CURRENT_UNIT;

    $self->{result} = shift;

    return $self;
}

sub has_result {
    my $self = blessed $_[0] ? shift : $CURRENT_UNIT;

    return if defined $self->{result};
}

sub _header {
    my $self = shift;

    my $timestamp = gmtime();
    my $type      = 'UOW';
    my $log_level = '%LOG_LEVEL%';
    my $host_name = '';
    my $program   = $0;
    my $pid       = $$;
    my $tid       = 0;
    my $pvid      = $self->{id};
    my $namespace = $self->{namespace};
    my $name      = $self->{name};

    return [
        $timestamp,
        $type,
        $log_level,
        $host_name,
        $program,
        $pid,
        $tid,
        $pvid,
        $namespace,
    ];
}


1;
