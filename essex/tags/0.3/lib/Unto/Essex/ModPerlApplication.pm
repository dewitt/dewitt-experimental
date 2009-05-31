package Unto::Essex::ModPerlApplication;

use strict;
use Error;
use Unto::Essex::ServiceManager( );
use Apache2::RequestRec( );
use Apache2::RequestUtil( );

my $Service_Manager;

sub handler
{
  my ( $request ) = @_;

  my $service_manager = get_service_manager( $request ) or
    throw Error::Simple( "Couldn't get service manager" );
  
  my $dispatcher = $service_manager->lookup( 'dispatcher' ) or
    throw Error::Simple( "Couldn't get dispatcher" );

  $dispatcher->dispatch( $request );

  $service_manager->release( $dispatcher );
}


sub get_service_manager
{
  my ( $request ) = @_;

  if ( not defined $Service_Manager )
  {
    my $conf_file = $request->dir_config( "EssexConfiguration" ) or
      throw Error::Simple( "Couldn't find EssexConfiguration." );

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
