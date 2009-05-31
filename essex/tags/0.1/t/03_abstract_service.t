#!/usr/bin/perl -w

##
# Test logic
##

package Unto::Essex::AbstractServiceTest;

print "1..1\n";

our $i = 1;

sub pass
{
  print "ok " . $i++ . "\n";
}

sub fail
{
  print "not ok " . $i++ . "\n";
}

1;

##
# TestService class
##

package Unto::Essex::TestService;
use base qw( Unto::Essex::AbstractService );

sub say_hello
{
  return "Hello";
}

1;


##
# Back to the test logic
##

package Unto::Essex::AbstractServiceTest;

use Unto::Essex::ServiceManager( );

my $service_manager =
  new Unto::Essex::ServiceManager( "t/conf/services.yml", 
                                   "t/conf/configuration.yml" );
my $configuration = { 'foo' => 'bar' };

my $ts = new Unto::Essex::TestService( );

$ts->service( $service_manager );
$ts->configure( $configuration );
$ts->initialize( );
$ts->say_hello( ) eq 'Hello' ? pass( ) : fail( );
$ts->dispose( );

$service_manager->dispose( );

1;
