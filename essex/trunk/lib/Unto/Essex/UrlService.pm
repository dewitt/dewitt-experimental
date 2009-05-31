package Unto::Essex::UrlService;

use strict;
use base qw( Unto::Essex::AbstractService );
use Unto::Essex::Assert qw( assert );
use HTTP::Request;
use HTTP::Response;
use HTTP::Status;
use LWP::UserAgent;

use constant CACHE_NAMESPACE => 'Unto::Essex::UrlService';
use constant MAX_ATTEMPTS => 5;

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


sub _get_agent
{
  my ( $self ) = @_;

  my %options;
  my $useragent = $self->_get_conf_key( 'useragent' );
  my $timeout = $self->_get_conf_key( 'timeout' );
  $options{ 'agent' } = $useragent if defined $useragent;
  $options{ 'timeout' } = $timeout if defined $timeout;
  my $agent = new LWP::UserAgent( %options ) or
    throw Error::Simple( "Couldn't initialize LWP::UserAgent" );
  return $agent;
}

sub post_url
{
  my ( $self, $url, $headers, $content, $username, $password ) = @_;

  my $agent = $self->_get_agent( ) or 
    throw Error::Simple( "Couldn't initialize agent" );

  my $request = new HTTP::Request( 'POST', $url, $headers, $content ) or
    throw Error::Simple( "Couldn't initialize POST request for '$url'" );

  if ( defined $username or defined $password )
  {
    $request->authorization_basic( $username, $password );
  }

  my $response = $self->_make_request( $agent, $request ) or
    throw Error::Simple( "Couldn't get response for '$url'" );

  return $response->content( );
}


sub cached_post_url
{
  my ( $self, $url, $headers, $content, $username, $password ) = @_;

  my $key = $self->_build_key( $url, $content, $username, $password );

  my $data = $self->_get_cached_value( $key );

  if ( not defined $data )
  {
    $data = 
      $self->post_url( $url, $headers, $content, $username, $password ) or
        throw Error::Simple( "Couldn't post to $url" );

    $self->_set_cached_value( $key, $data );
  }

  return $data;
}


sub fetch_url
{
  my ( $self, $url, $username, $password ) = @_;

  assert( $url, "url" );

  my $content = $self->_get_cached_value( $url );

  if ( not defined $content )
  {
    $content = $self->fetch_url_no_cache( $url, $username, $password );
  }

  if ( $content )
  {
    $self->_set_cached_value( $url, $content );
  }    

  return $content;
}


sub fetch_url_no_cache
{
  my ( $self, $url, $username, $password ) = @_;

  assert( $url, "url" );

  my $agent = $self->_get_agent( ) or 
    throw Error::Simple( "Couldn't initialize agent" );

  my $request = new HTTP::Request( 'GET', $url ) or
    throw Error::Simple( "Couldn't initialize GET request for '$url'" );

  if ( defined $username or defined $password )
  {
    $request->authorization_basic( $username, $password );
  }

  my $response = $self->_make_request( $agent, $request ) or
    throw Error::Simple( "Couldn't get response for '$url'" );

  return $response->content( );
}


sub purge_cache
{
  my ( $self ) = @_;

  my $cache_service = $self->_get_cache_service( ) or
    return undef;

  my $cache = $cache_service->get_cache( CACHE_NAMESPACE ) or
    throw Error::Simple( "Couldn't get cache" );

  $cache->purge( );
}


sub _build_key
{
  my ( $self, @components ) = @_;

  my @copy;

  foreach my $component ( @components )
  {
    push( @copy, ( defined $component ? $component : '' ) );
  }

  return join( ':', @copy );
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


sub _make_request
{
  my ( $self, $agent, $request ) = @_;

  my $last_error;

  for ( my $i = 0; $i < MAX_ATTEMPTS; $i++ )
  { 
    my $response = $agent->request( $request ) or
      throw Error::Simple( "Couldn't get response for '" . $request->uri( ) . "'" );

    if ( $response->is_success( ) )
    {
      return $response;
    }
    elsif ( !$self->_should_retry( $response ) )
    {
      throw Error::Simple( "Couldn't post to '" . $request->uri( ) . "' with '" . $request->content( ) . "': " . $response->status_line( ) );
    }
    else
    {
      $last_error = $response->status_line( );
    }
  }

  throw Error::Simple( "Couldn't post to '" . $request->uri( ) . "' with '" . $request->content( ) . "': " . $last_error );
}


sub _should_retry
{           
  my ( $self, $response ) = @_;

  return ( $response->is_error( ) && ( $response->code( ) == RC_BAD_GATEWAY ) );
}

1;

=pod

=head1 NAME

Unto::Essex::UrlService -- A LWP service, with caching

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
