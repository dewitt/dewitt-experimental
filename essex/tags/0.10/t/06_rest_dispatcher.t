#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 11 };

##
# Fake Request
##

package FakeRequest;

use base qw( Unto::Essex::Object );
use Unto::Essex::Assert qw( assert );
use property _path_info => 'SCALAR';
use property _method => 'SCALAR';

sub new
{
  my ( $proto, $path_info, $method ) = @_;
  my $class = ref( $proto ) || $proto;
  my $self  = $class->SUPER::new( );
  bless( $self, $class );
  assert( $path_info, "path_info" );
  assert( $method, "method" );
  $self->_set_path_info( $path_info );
  $self->_set_method( $method );
  return $self;
}

sub path_info
{
  my ( $self ) = @_;
  return $self->_get_path_info( );
}


sub method
{
  my ( $self ) = @_;
  return $self->_get_method( );
}


1;

##
# Test logic
##

package main;

use Unto::Essex::ServiceManager;
use Unto::Essex::RestDispatcher;
use Error qw( :try );

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/configuration.yml" );

ok( $service_manager->has_service( "dispatcher" ) );

my $dispatcher = $service_manager->lookup( 'dispatcher' );
my $r1 = new FakeRequest( '/no-hello/', 'GET' );

try
{
  $dispatcher->dispatch( $r1 );
}
catch Error::Simple with
{
  ok( 1 );
}
otherwise
{
  ok( 0 );
};

make_request( $dispatcher, '/', 'GET', "Hello World!" );
make_request( $dispatcher, '/hello/', 'GET', "Hello World!" );
make_request( $dispatcher, '/hello/something/', 'GET', 'something' );
make_request( $dispatcher, '/goodbye/something/', 'GET', 'something' );
make_request( $dispatcher, '/goodbye/something/', 'POST',
              'different something' );
make_request( $dispatcher, '/goodbye/something/', 'PUT',
              'something interesting' );
make_request( $dispatcher, '/hello/hello/hello/hello', 'POST', 'hello:hello' );
make_request( $dispatcher, '/hello/hello/hello/goodbye/hello', 'POST',
              'hello:goodbye:hello' );
make_request( $dispatcher, '/optional/hello/', 'GET', 'hello-' );
make_request( $dispatcher, '/optional/hello/goodbye', 'GET', 'hello-goodbye' );

$service_manager->release( $dispatcher );
$service_manager->dispose( );


sub make_request
{
  my ( $dispatcher, $path, $method, $expected ) = @_;
  my $r = new FakeRequest( $path, $method );
  ok( $dispatcher->dispatch( $r ), $expected );
}

1;



