#!/usr/bin/perl -w


use strict;
use Test;

BEGIN { plan tests => 7 };

##
# Test logic
##

use Error qw( :try );
use Unto::Essex::ServiceManager;
use Unto::Essex::CacheService;

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "cache" ) );

my $service = $service_manager->lookup( "cache" );

ok( $service );

my $cache = $service->get_cache( );

ok( $cache );

$cache->set( 'foo', 'bar' );

ok( $cache->get( 'foo' ), 'bar' );

my $cache2 = $service->get_cache( 'TEST' );

ok( $cache2 );

ok( not defined $cache2->get( 'foo' ) );

$cache2->set( 'foo2', 'bar' );

ok( $cache2->get( 'foo2' ) );

$service_manager->release( $service );

$service_manager->dispose( );

1;

