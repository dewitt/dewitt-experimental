#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 3 };

##
# Test logic
##

use Unto::Essex::ServiceManager;

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "hello" ) );

ok( !$service_manager->has_service( "nohello" ) );

my $hello_service = $service_manager->lookup( "hello" );

ok( $hello_service->say_hello( ), 'Hello World!' );

$service_manager->release( $hello_service );

$service_manager->dispose( );

1;
