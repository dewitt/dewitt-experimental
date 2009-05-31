package Unto::Essex::ModPerlApplication;

use strict;
use Error;
use Unto::Essex::ServiceManager( );
use Apache2::RequestRec( );
use Apache2::RequestUtil( );
use Apache2::Request( );
use Apache2::Const -compile => qw( OK );
use File::Spec;
use Apache2::ServerUtil;

my $Service_Manager;

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

  $dispatcher->dispatch( $request );

  $service_manager->release( $dispatcher );

  return Apache2::Const::OK;
}


sub get_service_manager
{
  my ( $request ) = @_;

  if ( not defined $Service_Manager )
  {
    my $conf_file = $request->dir_config( "EssexConfiguration" ) or
      throw Error::Simple( "Couldn't find EssexConfiguration." );

    if ( $conf_file !~ /^\// )
    {
      $conf_file = 
        File::Spec->catfile( Apache2::ServerUtil::server_root( ), $conf_file );
    }

    $Service_Manager = new Unto::Essex::ServiceManager( $conf_file ) or
      throw Error::Simple( "Couldn't instantiate ServiceManager" );
  }

  return $Service_Manager;
}

1;

=pod

=head1 NAME

Unto::Essex::ModPerlApplication -- an entry-point for mod_perl code

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
