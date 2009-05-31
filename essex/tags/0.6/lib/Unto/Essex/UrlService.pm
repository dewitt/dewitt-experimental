package Unto::Essex::UrlService;

use strict;
use base qw( Unto::Essex::AbstractService );
use Unto::Essex::Assert qw( assert );
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;

use constant CACHE_NAMESPACE => 'Unto::Essex::UrlService';

use property _cache_service => 'Unto::Essex::CacheService';

sub initialize
{
  my ( $self ) = @_;

  $self->SUPER::initialize( );

  if ( $self->_has_service( 'cache' ) )
  {
    my $cache_service = $self->_lookup( 'cache' );
    $self->_set_cache_service( $cache_service );
  }
}

sub dispose
{
  my ( $self ) = @_;

  my $cache_service = $self->_get_cache_service( );

  if ( defined $cache_service )
  {
    $self->_release( $cache_service );
  }

  $self->SUPER::dispose( );
}


sub post_url
{
  my ( $self, $url, $headers, $content ) = @_;

  my $agent = new LWP::UserAgent( ) or
    throw Error::Simple( "Couldn't initialize LWP::UserAgent" );

  my $timeout = $self->_get_conf_key( 'timeout' );

  $agent->timeout( $timeout ) if defined $timeout;

  my $request = new HTTP::Request( 'POST', $url, $headers, $content ) or
    throw Error::Simple( "Couldn't initialize POST request for '$url'" );

  my $response = $agent->request( $request ) or
    throw Error::Simple( "Couldn't get response for '$url'" );

  if ( $response->is_error( ) )
  {
    throw Error::Simple( "Couldn't post to '$url' with '$content': " . $response->status_line( ) );
  }

  return $response->content( );
}


sub cached_post_url
{
  my ( $self, $url, $headers, $content ) = @_;

  my $key = join( ':', $url, $content );

  my $data = $self->_get_cached_value( $key );

  if ( not defined $data )
  {
    $data = $self->post_url( $url, $headers, $content ) or
      throw Error::Simple( "Couldn't post to $url" );

    $self->_set_cached_value( $key, $data );
  }

  return $data;
}


sub fetch_url
{
  my ( $self, $url ) = @_;

  assert( $url, "url" );

  my $content = $self->_get_cached_value( $url );

  if ( not defined $content )
  {
    my $agent = new LWP::UserAgent( ) or
      throw Error::Simple( "Couldn't initialize LWP::UserAgent" );

    my $timeout = $self->_get_conf_key( 'timeout' );

    $agent->timeout( $timeout ) if defined $timeout;

    my $request = new HTTP::Request( 'GET', $url ) or
      throw Error::Simple( "Couldn't initialize GET request for '$url'" );

    my $response = $agent->request( $request ) or
      throw Error::Simple( "Couldn't get response for '$url'" );

    if ( $response->is_error( ) )
    {
      throw Error::Simple( "Couldn't get '$url': " . 
                           $response->status_line( ) );
    }

    $content = $response->content( );

    $self->_set_cached_value( $url, $content );
  }

  return $content;
}


sub _get_cached_value
{
  my ( $self, $key ) = @_;

  my $cache_service = $self->_get_cache_service( ) or
    return undef;

  my $cache = $cache_service->get_cache( CACHE_NAMESPACE ) or
    throw Error::Simple( "Couldn't get cache" );

  return $cache->get( $key );
}


sub _set_cached_value
{
  my ( $self, $key, $value ) = @_;

  my $cache_service = $self->_get_cache_service( ) or
    return;

  my $cache = $cache_service->get_cache( CACHE_NAMESPACE ) or
    throw Error::Simple( "Couldn't get cache" );

  $cache->set( $key, $value );
}


1;

=pod

=head1 NAME

Unto::Essex::UrlService -- A LWP service, with caching

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
