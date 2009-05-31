#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 10 };

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

package main;

my $tdt = new Unto::Essex::TestDataType( );

$tdt->set_scalar( 'test' );
ok( $tdt->get_scalar( ), 'test' );
$tdt->set_hash( { 'foo' => 'bar' } );
ok( $tdt->get_hash( )->{ 'foo' }, 'bar' );
$tdt->set_object( $tdt );
ok( $tdt->get_object( )->get_scalar( ), 'test' );
$tdt->set_untyped( 123 );
ok( $tdt->get_untyped( ), 123 );
$tdt->_set_private( 'test' );
ok( $tdt->_get_private( ), 'test' );

my $tdts = new Unto::Essex::TestDataTypeSubclass( );

$tdts->set_scalar( 'test' );
ok( $tdts->get_scalar( ),  'test' );
$tdts->set_scalar2( 'test' );
ok( $tdts->get_scalar2( ), 'test' );


my $tdtsf = new Unto::Essex::TestDataTypeShortForm( );

$tdtsf->set_foo( 'test' );
ok( $tdtsf->get_foo( ), 'test' );
$tdtsf->set_bar( 'test' );
ok( $tdtsf->get_bar( ), 'test' );
$tdtsf->set_cat( 'test' );
ok( $tdtsf->get_cat( ), 'test' );



