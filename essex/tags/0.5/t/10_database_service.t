#!/usr/bin/perl -w


use strict;
use Test;

BEGIN { plan tests => 2 };

##
# Test logic
##

use Error qw( :try );
use Unto::Essex::ServiceManager;
use Unto::Essex::DatabaseService;

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "test-database" ) );

my $service = $service_manager->lookup( "test-database" );

ok( $service );

$service_manager->release( $service );

$service_manager->dispose( );

1;
