#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 3 };

##
# Test logic
##

use Error qw( :try );
use Unto::Essex::ServiceManager;
use Unto::Essex::UrlService;

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "url" ) );

my $service = $service_manager->lookup( "url" );

ok( $service );

my $content = $service->fetch_url( "http://www.unto.net/essex_test.txt" );

ok( $content );

$service_manager->release( $service );

1;


