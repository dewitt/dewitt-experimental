package Unto::Essex::AbstractService;

##
# Imports
##

use strict;
use base qw( Unto::Essex::Object );
use Unto::Essex::Assert qw( assert );

##
# Properties and constants
##

use constant LOG_SERVICE => 'logger';
use property _configuration => 'HASH';
use property _service_manager => 'Unto::Essex::ServiceManager';
use property _is_configured => 'SCALAR';
use property _is_serviced => 'SCALAR';
use property _is_initialized => 'SCALAR';
use property _is_disposed => 'SCALAR';
use property _services => 'ARRAY';

##
# Public
##

sub service
{
  my ( $self, $service_manager ) = @_;
  assert( $service_manager, "service_manager" );
  $self->_set_service_manager( $service_manager );
  $self->_set_is_serviced( 1 );
}

sub initialize
{
  my ( $self ) = @_;
  $self->_set_services( [ ] );
  $self->_set_is_initialized( 1 );
  $self->_set_is_disposed( 0 );
}


sub configure
{
  my ( $self, $configuration ) = @_;
  assert( $configuration, "configuration" );
  $self->_set_configuration( $configuration );
  $self->_set_is_configured( 1 );
}


sub reconfigure
{
  my ( $self, $configuration ) = @_;
  assert( $configuration, "configuration" );
  assert( $self->_get_is_configured( ), "is configured" );
  $self->_set_configuration( $configuration );
}


sub dispose
{
  my ( $self ) = @_;
  assert( !$self->_get_is_disposed( ), "not is disposed" );
  assert( $self->_get_is_configured( ), "is configured" );
  assert( $self->_get_is_serviced( ), "is serviced" );
  assert( $self->_get_is_initialized( ), "is initialized" );
  my @services = @{$self->_get_services( )};
  foreach my $service ( @services )
  {
    $self->_get_service_manager( )->release( $service );
  }
  $self->_set_services( [ ] );
  $self->_set_configuration( undef );
  $self->_set_is_configured( 0 );
  $self->_set_service_manager( undef );
  $self->_set_is_serviced( 0 );
  $self->_set_is_disposed( 1 );
  assert( !$self->_get_is_configured( ), "not is configured" );
  assert( !$self->_get_is_serviced( ), "not is serviced" );
  assert( $self->_get_is_disposed( ), "is disposed" );
}



##
# Private
##

sub _has_service
{
  my ( $self, $name ) = @_;
  assert( $name, 'name' );
  return $self->_get_service_manager( )->has_service( $name );
}

sub _lookup
{
  my ( $self, $name ) = @_;
  assert( $name, 'name' );
  my $service = $self->_get_service_manager( )->lookup( $name ) or
    throw Error::Simple( "Service $name not defined" );
  push( @{$self->_get_services( )}, $service );
  return $service;
}


sub _release
{
  my ( $self, $service ) = @_;
  assert( $service, 'service' );

  $self->_get_service_manager( )->release( $service );
  my @services = grep( !$service, @{$self->_get_services( )} );
  $self->_set_services( \@services );
}


sub _get_logger
{
  my ( $self ) = @_;
  return $self->_lookup( LOG_SERVICE );
}

sub _log_emerg
{
  my ( $self, $message ) = @_;
  $self->_get_logger( )->log_emerg( $message );
}


sub _log_alert
{
  my ( $self, $message ) = @_;
  $self->_get_logger( )->log_alert( $message );
}


sub _log_crit
{
  my ( $self, $message ) = @_;
  $self->_get_logger( )->log_crit( $message );
}


sub _log_error
{
  my ( $self, $message ) = @_;
  $self->_get_logger( )->log_error( $message );
}


sub _log_warn
{
  my ( $self, $message ) = @_;
  $self->_get_logger( )->log_warn( $message );
}


sub _log_notice
{
  my ( $self, $message ) = @_;
  $self->_get_logger( )->log_notice( $message );
}


sub _log_info
{
  my ( $self, $message ) = @_;
  $self->_get_logger( )->log_info( $message );
}


sub _log_debug
{
  my ( $self, $message ) = @_;
  $self->_get_logger( )->log_debug( $message );
}

sub _get_conf_key
{
  my ( $self, $key ) = @_;
  assert( $key, "key" );
  return $self->_get_configuration( )->{ $key };
}


1;

=pod

=head1 NAME

Unto::Essex::AbstractService -- service base class

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
