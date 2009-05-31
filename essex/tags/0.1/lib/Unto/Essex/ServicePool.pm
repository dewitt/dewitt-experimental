package Unto::Essex::ServicePool;

##
# Imports
##

use strict;
use base qw( Unto::Essex::Object );
use Error;
use Unto::Essex::Assert qw( assert );

##
# Properties and constants
##

use constant ACTIVE => 1;
use constant IDLE => 0;
use property _service_manager => 'Unto::Essex::ServiceManager';
use property _max_size => 'SCALAR';
use property _role => 'SCALAR';
use property _services => 'HASH';
use property _states => 'HASH';

##
# Public
##

sub new
{
  my ( $proto, $service_manager, $role, $max_size ) = @_;
  assert( $service_manager, "service_manager" );
  assert( $role, "role" );
  assert( $max_size, "max_size" );
  my $class = ref( $proto ) || $proto;
  my $self  = $class->SUPER::new( );
  bless( $self, $class );
  $self->_set_service_manager( $service_manager );
  $self->_set_max_size( $max_size );
  $self->_set_role( $role );
  $self->_set_services( { } );
  $self->_set_states( { } );
  return( $self );
}


sub get
{
  my ( $self ) = @_;

  throw Error::Simple( "Pool size exceeds maximum" ) if
    $self->_get_active_count( ) >= $self->_get_max_size( );

  if ( my $id = $self->_get_next_idle( ) )
  {
    $self->_get_states( )->{ $id } = ACTIVE;
    return $self->_get_service( $id );
  }

  my $service = 
    $self->_get_service_manager( )->_get_service( $self->_get_role( ) );

  my $id = scalar $service;
  $self->_get_states( )->{ $id } = ACTIVE;
  $self->_get_services( )->{ $id } = $service;
  return $service;
}


sub trim
{
  my ( $self ) = @_;
  my $count = 0;
  foreach my $id ( keys %{$self->_get_states( )} )
  {
    if ( $self->_get_states( )->{ $id } == IDLE )
    {
      $self->remove( $self->_get_services( )->{ $id } );
    }
  }
}


sub remove
{
  my ( $self, $service ) = @_;
  assert( $service, "service" );

  my $id = scalar $service;

  exists $self->_get_services( )->{ $id } or
    throw Error::Simple( "Pool not managing $service" );

  exists $self->_get_states( )->{ $id } or
    throw Error::Simple( "Pool not managing $service" );

  $self->_get_states( )->{ $id } == IDLE or
    throw Error::Simple( "Service not idle.  Trying returning it first." );

  delete $self->_get_states( )->{ $id };
  delete $self->_get_services( )->{ $id };
}


sub put
{
  my ( $self, $service ) = @_;
  assert( $service, "service" );

  my $id = scalar $service;

  exists $self->_get_services( )->{ $id } or
    throw Error::Simple( "Pool not managing $service" );

  exists $self->_get_states( )->{ $id } or
    throw Error::Simple( "Pool not managing $service" );

  $self->_get_states( )->{ $id } = IDLE;
}


sub drain
{
  my ( $self ) = @_;

  foreach my $id ( keys %{$self->_get_states( )} )
  {
    my $service = $self->_get_services( )->{ $id };
    if ( $self->_get_states( )->{ $id } == ACTIVE )
    {
      $self->put( $service );
    }
    $self->remove( $service );
    $self->_get_service_manager( )->_release_service( $service );
  }
}


##
# Private
##

sub _get_active_count
{
  my ( $self ) = @_;
  my $count = 0;
  foreach my $state ( values %{$self->_get_states( )} )
  {
    $count++ if $state == ACTIVE;
  }
  return $count;
}


sub _get_total_count
{
  my ( $self ) = @_;
  return scalar keys %{$self->_get_states( )};
}


sub _get_next_idle
{
  my ( $self ) = @_;
  my $count = 0;
  foreach my $id ( keys %{$self->_get_states( )} )
  {
    return $id if $self->_get_states( )->{ $id } == IDLE;
  }
  return undef;
}

sub _get_service
{
  my ( $self, $id ) = @_;
  assert( $id, "id" );
  return $self->_get_services( )->{ $id };
}

1;


=pod

=head1 NAME

Unto::Essex::ServicePool -- maintain a pool of services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton <dewitt@unto.net>

=cut
