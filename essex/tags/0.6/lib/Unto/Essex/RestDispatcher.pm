package Unto::Essex::RestDispatcher;

use strict;
use base qw( Unto::Essex::AbstractService );
use Unto::Essex::Assert qw( assert );
use Error;

use property _dispatcher_tree => 'HASH';

##
# Public
##

sub configure
{
  my ( $self, $configuration ) = @_;
  $self->SUPER::configure( $configuration );
}

sub dispatch
{
  my ( $self, $request ) = @_;

  assert( $request, "request" );

  my ( $dispatcher, $params ) = $self->_get_dispatcher( $request ) or
    throw Error::Simple( "Couldn't find dispatcher for path '" .
                         $request->path_info( ) . "'" );

  assert( $dispatcher, "dispatcher" );

  my $handler = $self->_get_handler( $dispatcher, $request ) or
    throw Error::Simple( "Couldn't get handler" );

  my $service_name = $dispatcher->{ 'service' } or
    throw Error::Simple( "Couldn't get service name for dispatcher" );

  my $service = $self->_get_service_manager( )->lookup( $service_name ) or
    throw Error::Simple( "Couldn't get service for $service_name" );

  if ( not $service->can( $handler ) )
  {
    $self->_get_service_manager( )->release( $service );
    throw Error::Simple( "Service '$service_name' can't '$handler'" );
  }

  no strict 'refs';

  my $retval = $service->$handler( $request, $params );

  use strict;

  $self->_get_service_manager( )->release( $service );

  return $retval;
}


# Check the configuration to find the appropriate handler.  If there
# is a configuration key for the dispatcher in the form '[method]-handler'
# then use that.  Otherwise if there is one called 'handler', use that.
# If all else fails, try calling one called 'do_[method]'.

sub _get_handler
{
  my ( $self, $dispatcher, $request ) = @_;
  assert( $dispatcher, "dispatcher" );
  assert( $request, "request" );

  my $method = $request->method( ) or
    throw Error::Simple( "Couldn't get request method" );

  if ( exists $dispatcher->{ lc $method . '-handler' } )
  {
    return $dispatcher->{ lc $method . '-handler' };
  }
  elsif ( exists $dispatcher->{ 'handler' } )
  {
    return $dispatcher->{ 'handler' };
  }
  else
  {
    return 'do_' . lc $method;
  }
}


sub _get_dispatcher
{
  my ( $self, $request ) = @_;

  assert( $request, "request" );

  my $path = $request->path_info( ) or
    throw Error::Simple( "Couldn't get path info for request" );

  my $best_dispatcher = undef;
  my $best_dispatcher_params = undef;
  my $best_dispatcher_length = 0;
  my $is_ambiguous = 0;

  my $configuration = $self->_get_configuration( );

  my @dispatchers = @{$configuration->{ 'dispatchers' }} or
    throw Error::Simple( "No dispatchers available." );

  foreach my $dispatcher ( @dispatchers )
  {
    if ( my $params = $self->_match_dispatcher( $dispatcher, $path ) )
    {
      my $length = $self->_get_dispatcher_length( $dispatcher );

      if ( $length > $best_dispatcher_length )
      {
        $best_dispatcher = $dispatcher;
        $best_dispatcher_params = $params;
        $best_dispatcher_length = $length;
        $is_ambiguous = 0;
      }
      elsif ( $length == $best_dispatcher_length )
      {
        $is_ambiguous = 1;
      }
    }
  }

  if ( not defined $best_dispatcher )
  {
    throw Error::Simple( "No dispatchers found for path '$path'" );
  }
  elsif ( $is_ambiguous )
  {
    throw Error::Simple( "Ambigous dispatchers found for path '$path'" );
  }

  return ( $best_dispatcher, $best_dispatcher_params );
}


sub _match_dispatcher
{
  my ( $self, $dispatcher, $path ) = @_;
  assert( $dispatcher, "dispatcher" );
  assert( $path, "path" );

  my $dispatcher_path = $dispatcher->{ 'path' } or
    throw Error::Simple( "Dispatcher has no path" );

  my @dispatcher_elements = $self->_get_elements( $dispatcher_path ) or
    throw Error::Simple( "Dispatcher path has no elements" );

  my @path_elements = $self->_get_elements( $path ) or
    throw Error::Simple( "Request has no path" );

  my $params = { };

  while( @dispatcher_elements )
  {
    my $dispatcher_element = shift( @dispatcher_elements ) or
      throw Error::Simple( "Invalid dispatcher element" );

    my $optional = $dispatcher_element =~ m/^\[\w+\?\]$/;

    my $path_element = shift( @path_elements );

    return undef if not defined $path_element and not $optional;

    if ( my ( $key ) = $dispatcher_element =~ m/^\[(\w+)\??\]$/ )
    {
      $params->{ $key } = $path_element;
    }
    elsif ( $dispatcher_element ne $path_element )
    {
      return undef;
    }
  }

  $params->{ _UNMATCHED_ } = \@path_elements;

  return $params;
}


sub _get_dispatcher_length
{
  my ( $self, $dispatcher ) = @_;
  assert( $dispatcher, "dispatcher" );

  my $dispatcher_path = $dispatcher->{ 'path' } or
    throw Error::Simple( "Dispatcher has no path" );

  return scalar $self->_get_elements( $dispatcher_path );
}


sub _get_elements
{
  my ( $self, $path ) = @_;
  assert( $path, "path" );
  return grep( /\w\??/, split( /\s*?\/+/, $path ) );
}


1;


=pod

=head1 NAME

Unto::Essex::RestDispatcher -- invoke services based on request path

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
