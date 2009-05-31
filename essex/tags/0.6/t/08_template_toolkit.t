#!/usr/bin/perl -w

use strict;
use Test qw( plan ok );

BEGIN { plan tests => 3 };

use Unto::Essex::ServiceManager( );
use Unto::Essex::TemplateToolkitService( );

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

my $template = $service_manager->lookup( 'template-toolkit' );

ok( $template );

my $vars = { 'salutation' => 'Hello World' };

my $output;

ok( $template->process( 't/templates/test.tmpl', $vars, \$output ) );

ok( $output eq "Just saying Hello World.\n" );

$service_manager->release( $template );


1;
