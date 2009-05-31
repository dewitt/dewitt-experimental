#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 15 };

##
# Test logic
##

use Error qw( :try );
use Unto::Essex::ServiceManager;
use Unto::Essex::BerkeleyDatabaseService;

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "bdb" ) );

my $service = $service_manager->lookup( "bdb" );

ok( $service );

my $filename = 'database.db';

my $hash = $service->get_database_hash( $filename );

ok( -e $filename );

ok( $hash );

$hash->{ 'apple' } = 'red';
$hash->{ 'banana' } = 'yellow';

ok( $hash );

ok( $hash->{ 'apple' } eq 'red' );

$service_manager->release( $service );

my $service2 = $service_manager->lookup( "bdb" );

ok( $service2 );

my $hash2 = $service2->get_database_hash( $filename );

ok( $hash2 );

$hash2->{ 'apple' } = 'red';

ok( $hash2->{ 'apple' } eq 'red' );

$service_manager->release( $service2 );

unlink $filename;

ok( !-e $filename );

my $service3 = $service_manager->lookup( "bdb" );

ok( $service3 );

my $hash3 = $service3->get_database_hash( );

ok( $hash3 );

$hash3->{ 'apple' } = 'red';

ok( $hash3->{ 'apple' } eq 'red' );

ok( -e 'database2.db' );

$service_manager->release( $service3 );

unlink 'database2.db';

ok( !-e 'database2.db' );

1;



