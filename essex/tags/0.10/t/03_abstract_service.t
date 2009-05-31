#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 1 };

##
# TestService class
##

package Unto::Essex::TestService;
use base qw( Unto::Essex::AbstractService );

sub say_hello
{
  return "Hello";
}

1;


##
# Back to the test logic
##

package main;

use Unto::Essex::ServiceManager;

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );
my $configuration = { 'foo' => 'bar' };

my $ts = new Unto::Essex::TestService( );

$ts->service( $service_manager );
$ts->configure( $configuration );
$ts->initialize( );
ok( $ts->say_hello( ), 'Hello' );
$ts->dispose( );

$service_manager->dispose( );

1;
