use Test::More tests => 6;

BEGIN {
    use_ok( 'Log::ProvenanceId' );
    use_ok( 'Log::Work', qw(:simple));
    use_ok( 'Log::Lager' );
    use_ok( 'Log::Lager::Work' );
}

Log::Work->on_finish(sub { Log::Lager::Work->new(@_) });
Log::ProvenanceId->import("Test.t02");

my $foo = INFO WORK { return "Blah" } "Working";
is( $foo, "Blah", "scalar passthrough" );
my @foo = INFO WORK { return (1, 2, 3) } "Working";
is_deeply( \@foo, [ 1, 2, 3 ], "list passthrough" );

