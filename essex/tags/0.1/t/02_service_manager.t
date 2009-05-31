#!/usr/bin/perl -w

##
# Test logic
##

package Unto::Essex::ServiceManagerTest;

print "1..3\n";

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

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/services.yml",
                                   "t/conf/configuration.yml" );

$service_manager->has_service( "hello" ) ? pass( ) : fail( );

!$service_manager->has_service( "nohello" ) ? pass( ) : fail( );

my $hello_service = $service_manager->lookup( "hello" );

$hello_service->say_hello( ) eq 'Hello World!' ? pass( ) : fail( );

$service_manager->release( $hello_service );

$service_manager->dispose( );

1;
