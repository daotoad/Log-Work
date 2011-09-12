use Test::More tests => 22;

use strict;
use warnings;

use Log::Lager 'I';
use Log::Work::SimpleLager qw< :standard >;

use_ok( 'Log::Work::ProvenanceId', 'Holy.HandGrenade'  ) or BAIL_OUT( 'Failed to load critical module' );

WORK {
    my $id = get_id();
    warn "ID >$id<";
    like( $id, qr/^Holy\.HandGrenade/, 'Base id resembles root id' );
    ok( Log::Work::ProvenanceId::is_valid_root_prov_id( $id ), 'Id tests as valid root' );
    ok( Log::Work::ProvenanceId::is_valid_prov_id( $id ), 'Id tests as valid' );
    ok( Log::Work::ProvenanceId::is_local( $id ), 'Id tests as local' );

    WORK {

        my $kid = get_id();
        like( $kid, qr/^Holy\.HandGrenade/, 'Base id resembles root id' );
        ok( !Log::Work::ProvenanceId::is_valid_root_prov_id( $kid ), 'Kid tests as invalid root' );
        ok( Log::Work::ProvenanceId::is_valid_prov_id( $kid ), 'Kid tests as valid' );

        is( Log::Work::ProvenanceId::get_parent_id( $kid ), $id, 'get_parent_id() is correct' );
        ok( Log::Work::ProvenanceId::is_local( $kid ), 'Kid is not remote' );


        my $remote = new_remote_id();
        ok( !Log::Work::ProvenanceId::is_valid_root_prov_id( $remote ), 'Remote id tests as invalid root' );
        ok( Log::Work::ProvenanceId::is_valid_prov_id( $remote ), 'Remote id tests as valid' );
        is( Log::Work::ProvenanceId::get_parent_id( $remote ), $kid, 'get_parent_id() is correct' );
        ok( Log::Work::ProvenanceId::is_remote( $remote ), 'Remote id is remote' );

    } 'Inner test';

    my $remote = new_remote_id();
    ok( !Log::Work::ProvenanceId::is_valid_root_prov_id( $remote ), 'Remote id tests as invalid root' );
    ok( Log::Work::ProvenanceId::is_valid_prov_id( $remote ), 'Remote id tests as valid' );
    ok( Log::Work::ProvenanceId::is_remote( $remote ), 'Remote id is remote' );
    like( $remote, qr/2r$/, 'work counter increments' );

} 'Top level test';

# Invalid kid gets base id
my $kid = new_child_id();
like( $kid, qr/^Holy\.HandGrenade/, 'Base id resembles root id' );
ok( Log::Work::ProvenanceId::is_valid_root_prov_id( $kid ), 'Kid tests as valid root' );
ok( Log::Work::ProvenanceId::is_valid_prov_id( $kid ), 'Kid tests as valid' );
ok( Log::Work::ProvenanceId::is_local( $kid ), 'Kid is not remote' );

sub get_id {
    my $cu = Log::Work->current_unit;
    return $cu->{id};
}
