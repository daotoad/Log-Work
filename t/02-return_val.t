use Test::More;
BEGIN {
    eval {
        require Log::Lager;
        1;
    } or do {
        diag( "Attempting to load Log::Lager...\n", $@ );
        plan skip_all => "Log::Lager is not available";
    };
}

BEGIN {
    plan tests => 5;
    use_ok( 'Log::Work::ProvenanceId', 'Test.t02' );
    use_ok( 'Log::Work::SimpleLager', qw(:simple));
}

my $foo = INFO WORK { return "Blah" } "Working";
is( $foo, "Blah", "scalar passthrough" );
my @foo = INFO WORK { return (1, 2, 3) } "Working";
is_deeply( \@foo, [ 1, 2, 3 ], "list passthrough" );

eval {
  INFO WORK { die "gleep\n" } "Dying";
  fail("exception not rethrown");
  1;
} or do {
  is($@, "gleep\n", "exception passthrough");
}
