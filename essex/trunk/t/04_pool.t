#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 14 };

##
# Test logic
##

use Unto::Essex::ServiceManager;
use Unto::Essex::HelloService;
use Error qw( :try );

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "pooled-hello" ) );

my @services;

for ( my $i = 0; $i < 10; $i++ )
{
  my $service = $service_manager->lookup( "pooled-hello" );
  ok( $service->say_hello( ), 'Hello World!' );
  push( @services, $service );
}

try
{
  my $service = $service_manager->lookup( "pooled-hello" );
}
catch Error::Simple with
{
  ok( 1 );
}
otherwise
{
  ok( 0 );
};

foreach my $service ( @services )
{
  $service_manager->release( $service );
}

my $service = $service_manager->lookup( "pooled-hello" );
ok( $service->say_hello( ), 'Hello World!' );
ok( $service->get_recycle_count( ), 1 );

$service_manager->dispose( );

1;
