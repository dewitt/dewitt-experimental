package Unto::Delancey::ContentService;

##
# Imports
##

use strict;
use base qw( Unto::Essex::AbstractService );
use Error;

##
# Public
##

use property _site_info_data => 'HASH';

sub get_content
{
  my ( $self, $request, $params ) = @_;

  my $page = $params->{ 'page' } or
    throw Error::Simple( "page required" );

  if ( $page =~ m/[^\w_]/ )
  {
    throw Error::Simple( "Invalid page" );
  }

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );
  
  my $vars = { 'site_info' => $site_info };

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  $request->content_type( 'text/html' );

  $template_service->process( $page . '.tmpl', $vars );

  $self->_release( $template_service );
}


##
# Private
##

sub _get_site_info
{
  my ( $self, $request ) = @_;

  my $site_info = $self->_get_site_info_data( );

  if ( not defined $site_info )
  {
    my $site_info_service = $self->_lookup( 'site-info' ) or
      throw Error::Simple( "Couldn't lookup site info service" );

    $site_info = $site_info_service->get_site_info( $request ) or
      throw Error::Simple( "Couldn't get site info from service" );

    $self->_set_site_info_data( $site_info );

    $self->_release( $site_info_service );
  }

  return $site_info;
}

1;
