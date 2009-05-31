#!/usr/bin/perl -w

##
# Test logic
##

package Unto::Essex::PropertyTest;

print "1..10\n";


our $i = 1;

sub pass
{
  print "ok " . $i++ . "\n";
}

sub fail
{
  print "not ok " . $i++ . "\n";
}

1;


##
# TestDataType class
##

package Unto::Essex::TestDataType;
use base qw( Unto::Essex::Object );
use property scalar => 'SCALAR';
use property hash => 'HASH';
use property object => 'Unto::Essex::TestDataType';
use property untyped => undef;
use property _private => 'SCALAR';

1;

##
# TestDataTypeSubclass class
##

package Unto::Essex::TestDataTypeSubclass;
use base qw( Unto::Essex::TestDataType );
use property scalar2 => 'SCALAR';

1;



##
# TestDataTypeShortForm class
##

package Unto::Essex::TestDataTypeShortForm;
use base qw( Unto::Essex::Object );
use property foo => 'SCALAR';
use property bar => undef;
use property 'cat';

1;


##
# Back to the test logic
##

package Unto::Essex::PropertyTest;

my $tdt = new Unto::Essex::TestDataType( );

$tdt->set_scalar( 'test' );
$tdt->get_scalar eq 'test' ? pass( ) : fail( );
$tdt->set_hash( { 'foo' => 'bar' } );
$tdt->get_hash( )->{ 'foo' } eq 'bar' ? pass( ) : fail( );
$tdt->set_object( $tdt );
$tdt->get_object( )->get_scalar( ) eq 'test' ? pass( ) : fail( );
$tdt->set_untyped( 123 );
$tdt->get_untyped( ) eq 123 ? pass( ) : fail( );
$tdt->_set_private( 'test' );
$tdt->_get_private( ) eq 'test' ? pass( ) : fail( );

my $tdts = new Unto::Essex::TestDataTypeSubclass( );

$tdts->set_scalar( 'test' );
$tdts->get_scalar eq 'test' ? pass( ) : fail( );
$tdts->set_scalar2( 'test' );
$tdts->get_scalar2 eq 'test' ? pass( ) : fail( );


my $tdtsf = new Unto::Essex::TestDataTypeShortForm( );

$tdtsf->set_foo( 'test' );
$tdtsf->get_foo( ) eq 'test' ? pass( ) : fail( );
$tdtsf->set_bar( 'test' );
$tdtsf->get_bar( ) eq 'test' ? pass( ) : fail( );
$tdtsf->set_cat( 'test' );
$tdtsf->get_cat( ) eq 'test' ? pass( ) : fail( );


use strict;



