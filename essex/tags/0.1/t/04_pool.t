#!/usr/bin/perl -w

##
# Test logic
##

package Unto::Essex::PoolTest;
use strict;
use Error qw( :try );

print "1..14\n";

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

$service_manager->has_service( "pooled-hello" ) ? pass( ) : fail( );

my @services;

for ( my $i = 0; $i < 10; $i++ )
{
  my $service = $service_manager->lookup( "pooled-hello" );
  $service->say_hello( ) eq 'Hello World!' ? pass( ) : fail( );
  push( @services, $service );
}

try
{
  my $service = $service_manager->lookup( "pooled-hello" );
}
catch Error::Simple with
{
  pass( );
}
otherwise
{
  fail( );
};

foreach my $service ( @services )
{
  $service_manager->release( $service );
}

my $service = $service_manager->lookup( "pooled-hello" );
$service->say_hello( ) eq 'Hello World!' ? pass( ) : fail( );
$service->get_recycle_count( ) == 1 ? pass( ) : fail( );

$service_manager->dispose( );

1;
