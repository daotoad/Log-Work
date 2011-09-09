use Test::More tests => 4;

BEGIN {
    use_ok( 'Log::Work::ProvenanceId', 'Test.t02' );
    use_ok( 'Log::Work::SimpleLager', qw(:simple));
}

my $foo = INFO WORK { return "Blah" } "Working";
is( $foo, "Blah", "scalar passthrough" );
my @foo = INFO WORK { return (1, 2, 3) } "Working";
is_deeply( \@foo, [ 1, 2, 3 ], "list passthrough" );

