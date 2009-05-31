#!/usr/bin/perl -w


use strict;
use Test;

BEGIN { plan tests => 4 };

##
# Test logic
##

use Error qw( :try );
use Unto::Essex::ServiceManager;
use Unto::Essex::HelloService;

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "hello" ) );

my $service = $service_manager->lookup( "hello" );

ok( $service );

ok( $service->get_foo( ) eq 'bar' );

ok( $service->get_global_foo( ) eq 'bar' );

$service_manager->release( $service );

$service_manager->dispose( );

1;
