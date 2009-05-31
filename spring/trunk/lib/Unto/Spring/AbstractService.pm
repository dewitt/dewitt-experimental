package Unto::Spring::AbstractService;

use strict;
use base qw( Unto::Essex::AbstractService );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use Error;
use Unto::Essex::Assert qw( assert );
use Unto::Essex::CacheService;
use Unto::Essex::UrlService;
use Unto::Spring::SiteInfoService;

use property _site_info_data => 'HASH';
use constant CACHE_ENABLED => 1;

##
# Protected
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


sub _substitute_parameters
{
  my ( $self, $source_url, $search_parameters_ref ) = @_;

  my $url = $source_url;

  $url =~ s/(\&?)(\w+)=\{(\w+)\}/
          defined $search_parameters_ref->{ $3 } ?
           "$1$2=" . $self->_validate( $search_parameters_ref->{ $3 } ): 
           '' /xge;

  return $url;
}


sub _substitute_variables
{
  my ( $self, $source, $search_parameters_ref ) = @_;

  my $result = $source;

  $result =~ s/\{(\w+)\}/
    defined $search_parameters_ref->{ $1 } ?
    $self->_validate( $search_parameters_ref->{ $1 } ): 
    '' /xge;

  return $result;
}


sub _validate
{
  my ( $self, $value ) = @_;

  if ( $value =~ m/[^\:\/\w\s\+\-\%\.\"]/g )
  {
    throw Error::Simple( "Invalid value '$value'" );
  }

  return $value;
}


sub _fetch_url
{
  my ( $self, $url ) = @_;

  my $url_service = $self->_lookup( 'url' ) or
    throw Error::Simple( "Couldn't get UrlService" );

  my $content = $url_service->fetch_url( $url ) or
    throw Error::Simple( "Couldn't fetch $url" );

  $self->_release( $url_service );

  return $content;
}



sub _post_url
{
  my ( $self, $url, $headers, $content ) = @_;

  my $url_service = $self->_lookup( 'url' ) or
    throw Error::Simple( "Couldn't get UrlService" );

  my $response = $url_service->post_url( $url, $headers, $content ) or
    throw Error::Simple( "Couldn't fetch $url" );

  $self->_release( $url_service );

  return $response;
}



sub _cached_post_url
{
  my ( $self, $url, $headers, $content ) = @_;

  my $url_service = $self->_lookup( 'url' ) or
    throw Error::Simple( "Couldn't get UrlService" );

  my $response = $url_service->cached_post_url( $url, $headers, $content ) or
    throw Error::Simple( "Couldn't fetch $url" );

  $self->_release( $url_service );

  return $response;
}


sub _get_cache
{
  my ( $self ) = @_;

  return undef unless CACHE_ENABLED;

  my $cache = $self->_lookup( 'cache' ) or
    throw Error::Simple( "Couldn't get cache" );

  return $cache;
}


sub _release_cache
{
  my ( $self, $cache ) = @_;

  $self->_release( 'cache' ) if defined $cache;
}


sub _transform
{
  my ( $self, $content, $stylesheet_filename, %params ) = @_;

  my $xslt_service = $self->_lookup( 'xslt' ) or
    throw Error::Simple( "Couldn't get xslt service" );

  my $new_content = $xslt_service->transform( $content, $stylesheet_filename, %params ) or
    throw Error::Simple( "Couldn't transform content" );

  $self->_release( $xslt_service );

  return $new_content;
}



1;


=pod

=head1 NAME

Unto::Spring::AbstractService -- abstract base class for Spring services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut

