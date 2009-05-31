#!/usr/bin/perl -w


use strict;
use Test;

BEGIN { plan tests => 8 };

##
# Test logic
##

use Error qw( :try );
use Unto::Essex::ServiceManager;
use Unto::Essex::HelloService;

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "singleton-hello" ) );

my $service = $service_manager->lookup( "singleton-hello" );
ok( $service->say_hello( ), 'Hello World!' );
ok( $service->get_initialize_count( ), 1 );
my $id = scalar $service;

my $service2 = $service_manager->lookup( "singleton-hello" );
ok( $service2->say_hello( ), 'Hello World!' );
ok( $service2->get_initialize_count( ), 1 );
ok( $id, scalar $service2 );

$service_manager->release( $service );

$service = $service_manager->lookup( "singleton-hello" );

ok( $id, scalar $service );
ok( $service->get_initialize_count( ), 1 );

$service_manager->release( $service );
$service_manager->release( $service2 );

$service_manager->dispose( );

1;
