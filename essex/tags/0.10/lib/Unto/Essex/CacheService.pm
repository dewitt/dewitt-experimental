package Unto::Essex::CacheService;

use strict;
use base qw( Unto::Essex::AbstractService );
use Unto::Essex::Assert qw( assert );
use Cache::FileCache;
use Error;

use property _cache_map => 'HASH';

##
# Public
##

sub initialize
{
  my ( $self ) = @_;
  $self->SUPER::initialize( );
  $self->_set_cache_map( { } );
}

sub get_cache
{
  my ( $self, $namespace ) = @_;

  $namespace ||= $self->_get_conf_key( 'namespace' ) || 'Default';

  my $cache = $self->_get_cache_map( )->{ $namespace };

  if ( not defined $cache )
  {
    $cache = $self->_new_cache( $namespace ) or
      throw Error::Simple( "Couldn't instantiate new cache" );

    $self->_get_cache_map( )->{ $namespace } = $cache;
  }

  return $cache;
}


##
# Private
##

sub _new_cache
{
  my ( $self, $namespace ) = @_;

  assert( $namespace, 'namespace' );

  my $options = { 'namespace' => $namespace };

  for my $key ( 'cache_root', 'default_expires_in' )
  {
    my $value = $self->_get_conf_key( $key );
    $options->{ $key } = $value if defined $value;
  }

  my $cache = new Cache::FileCache( $options ) or
    throw Error::Simple( "Couldn't instantiate new cache" );

  return $cache;
}


1;


=pod

=head1 NAME

Unto::Essex::CacheService -- expose Cache::FileCache as a service

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
