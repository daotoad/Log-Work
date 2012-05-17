use Test::More tests => 27;
use Log::Work;

use Data::Dumper;


{   ## Test standard life cycle.
    Log::Work->on_error( sub{ fail( 'some test generated an error' ) } );
    my $finished = 0;
    Log::Work->on_finish( sub{ $finished++ } );

    my $outer = Log::Work->start( Outer => undef, 'PV.id');
    is( scalar $outer->get_children, 0, 'Outer object has no children');
    is( $outer->get_parent, undef, 'Outer object has no parent');
    is( $outer->get_top_unit, $outer, 'Outer object is top unit');

    {
        my $inner;
        $outer->step( sub {
            is( $outer, Log::Work::get_current_unit(), 'CURRENT UNIT is correct' );

            is( scalar $outer->get_children, 0, 'Step: Outer object has no children');
            is( $outer->get_parent, undef, 'Step: Outer object has no parent');
            is( $outer->get_top_unit, $outer, 'Step: Outer object is top unit');

            $inner = Log::Work->start('Inner');

            is( scalar $outer->get_children, 1, 'Step: Outer has one child');
            is( $outer->get_parent, undef, 'Step: Outer object has no parent');
            is( $outer->get_top_unit, $outer, 'Step: Outer object is top unit');

            $inner->step( sub {
                is( $inner, Log::Work::get_current_unit(), 'CURRENT UNIT is correct' );
                is( scalar $inner->get_children, 0, 'Inner Step: Inner object has no children');
                is( $inner->get_parent, $outer, 'Inner Step: Inner object has no parent');
                is( $inner->get_top_unit, $outer, 'Inner Step: Outer object is top unit');
                is( scalar $outer->get_children, 1, 'Inner Step: Outer has one child');
                is( $outer->get_parent, undef, 'Inner Step: Outer object has no parent');
                is( $outer->get_top_unit, $outer, 'Inner Step: Outer object is top unit');
            } );

        });

        is( scalar $outer->get_children, 1, 'Inner Step Ended: Outer has one child');
        is( $outer->get_parent, undef, 'Inner Step Ended: Outer object has no parent');
        is( $outer->get_top_unit, $outer, 'Inner Step Ended: Outer object is top unit');

        $inner->finish();
        is( $finished, 1, 'Inner finished: Finished count is correct' );
    }

    is( scalar $outer->get_children, 0, 'Inner finished: Outer object has no children');

    $outer->finish();
    is( $finished, 2, 'Outer finished: Finished count is correct' );

}

{   # Verify Error on unfinished unit being destroyed
    Log::Work->on_error( sub {
        my $u = pop;
        my $msg = shift;

        fail( 'some test generated an error' )
            unless $msg =~ /before finishing/;

        pass( 'Unfinished work caught going out of scope' );
        
    } );

    my $finished = 0;
    Log::Work->on_finish( sub{ $finished++ } );

    my $outer = Log::Work->start( Outer => undef, 'PV.id');

    {   my $inner;
        $outer->step( sub {
            $inner = Log::Work->start('Inner');
        } );
        is( $finished, 0, 'Finished count: 0' );
    }

    is( $finished, 1, 'Finished count: 1' );
    $outer->finish();
    is( $finished, 2, 'Finished count: 2' );
}
