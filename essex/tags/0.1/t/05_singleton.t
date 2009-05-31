#!/usr/bin/perl -w

##
# Test logic
##

package Unto::Essex::PoolTest;
use strict;
use Error qw( :try );

print "1..8\n";

our $i = 1;

sub pass
{
  print "ok " . $i++ . "\n";
}

sub fail
{
  print "not ok " . $i++ . "\n";
}

use Unto::Essex::ServiceManager( );
use Unto::Essex::HelloService( );

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/services.yml",
                                   "t/conf/configuration.yml" );

$service_manager->has_service( "singleton-hello" ) ? pass( ) : fail( );

my $service = $service_manager->lookup( "singleton-hello" );
$service->say_hello( ) eq 'Hello World!' ? pass( ) : fail( );
$service->get_initialize_count( ) == 1 ? pass( ) : fail( );
my $id = scalar $service;

my $service2 = $service_manager->lookup( "singleton-hello" );
$service2->say_hello( ) eq 'Hello World!' ? pass( ) : fail( );
$service2->get_initialize_count( ) == 1 ? pass( ) : fail( );
$id == scalar $service2 ? pass( ) : fail( );

$service_manager->release( $service );

$service = $service_manager->lookup( "singleton-hello" );

$id == scalar $service ? pass( ) : fail( );
$service->get_initialize_count( ) == 1 ? pass( ) : fail( );

$service_manager->release( $service );
$service_manager->release( $service2 );

$service_manager->dispose( );

1;
