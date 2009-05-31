package Unto::Essex::ModPerlApplication;

use strict;
use Error qw( :try );
use Unto::Essex::ServiceManager( );
use Apache2::RequestRec( );
use Apache2::RequestUtil( );
use Apache2::Request( );
use Apache2::Const -compile => qw( OK HTTP_INTERNAL_SERVER_ERROR );
use File::Spec;
use Apache2::ServerUtil;

$Error::Debug = 1;

our $service_manager_map = { };

# TODO: Add error handling

sub handler
{
  my ( $r ) = @_;

  my $request = new Apache2::Request( $r ) or
    throw Error::Simple( "Couldn't make Apache2::Request from request" );

  my $service_manager = get_service_manager( $request ) or
    throw Error::Simple( "Couldn't get service manager" );
  
  my $dispatcher = $service_manager->lookup( 'dispatcher' ) or
    throw Error::Simple( "Couldn't get dispatcher" );

  try
  {
    $dispatcher->dispatch( $request );
    return Apache2::Const::OK;
  }
  catch Error::Simple with 
  {
    my $error = shift;
    $r->content_type( "text/plain" );
    print "An error occurred: $error->{ '-text' }\n\n";

    if ( $Error::Debug )
    {
      print "In $error->{ '-file' }, line $error->{ '-line' }\n\n";
      print "Stacktrace:\n\n", $error->{ '-stacktrace' }, "\n\n";
    }
    return Apache2::Const::OK;
  }
  finally 
  {
    $service_manager->release( $dispatcher );
  }
}


sub get_service_manager
{
  my ( $request ) = @_;

  # TODO:  There are probably better ways to key this than location

  my $application_key = $request->location or
    throw Error::Simple( "Couldn't get application key from location" );

  my $service_manager = $service_manager_map->{ $application_key };

  if ( not defined $service_manager )
  {
    my $conf_file = $request->dir_config( "EssexConfiguration" ) or
      throw Error::Simple( "Couldn't find EssexConfiguration." );

    if ( $conf_file !~ /^\// )
    {
      $conf_file = 
        File::Spec->catfile( Apache2::ServerUtil::server_root( ), $conf_file );
    }

    $service_manager = 
      new Unto::Essex::ServiceManager( $conf_file, $application_key ) or
        throw Error::Simple( "Couldn't instantiate service_manager" );

    $service_manager_map->{ $application_key } = $service_manager;
  }

  return $service_manager;
}

1;

=pod

=head1 NAME

Unto::Essex::ModPerlApplication -- an entry-point for mod_perl code

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
