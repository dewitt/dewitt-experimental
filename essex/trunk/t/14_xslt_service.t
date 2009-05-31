#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 3 };

##
# Test logic
##

use Error qw( :try );
use Unto::Essex::ServiceManager;
use Unto::Essex::XsltService;

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "xslt" ) );

my $service = $service_manager->lookup( "xslt" );

ok( $service );

my $xml =<<END;
<?xml version="1.0" encoding="UTF-8" ?>

<Test>Hello World</Test>
END

my $content = $service->transform( $xml, 't/templates/test.xsl' );

ok( $content eq 'Hello World' );

$service_manager->release( $service );

1;


