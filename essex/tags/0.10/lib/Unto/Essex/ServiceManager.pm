package Unto::Essex::ServiceManager;

##
# Imports
##

use strict;
use base qw( Unto::Essex::Object );
use Unto::Essex::Assert qw( assert );
use Unto::Essex::ConfigurationParser;
use Unto::Essex::ServicePool;
use Error;

##
# Properties
##

use property _factory_map => 'HASH';
use property _service_map => 'HASH';
use property _configuration => 'HASH';
use property _namespace => 'SCALAR';
use property _pools => 'HASH';
use property _services => 'HASH';
use property _singletons => 'HASH';
use constant IDLE => 0;
use constant ACTIVE => 1;

##
# Public
##

sub new
{
  my ( $proto, $configuration_path, $namespace ) = @_;
  my $class = ref( $proto ) || $proto;
  my $self  = {};
  bless( $self, $class );
  assert( $configuration_path, "configuration_path" );
  $namespace ||= '_DEFAULT_';
  $self->_initialize_configuration( $configuration_path );
  $self->_initialize_service_map( );
  $self->_set_namespace( $namespace );
  $self->_set_factory_map( { } );
  $self->_set_pools( { } );
  $self->_set_services( { } );
  $self->_set_singletons( { } );
  return( $self );
}


sub has_service
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );
  return defined $self->_get_service_map( )->{ $name };
}


sub lookup
{
  my ( $self, $name ) = @_;

  assert( $name, "name" );

  if ( $self->_service_name_is_pooled( $name ) )
  {
    return $self->_get_pooled_service( $name );
  }
  elsif ( $self->_service_name_is_singleton( $name ) )
  {
    return $self->_get_singleton_service( $name );
  }
  else
  {
    return $self->_get_service( $name );
  }
}


sub release
{
  my ( $self, $service ) = @_;
  assert( $service, "service" );

  if ( $self->_service_is_pooled( $service ) )
  {
    $service->recycle( ) if $service->can( "recycle" );
    $self->_return_to_pool( $service );
  }
  elsif ( $self->_service_is_singleton( $service ) )
  {
     # do nothing
  }
  else
  {
    $self->_release_service( $service );
  }
}


sub dispose
{
  my ( $self ) = @_;

  foreach my $name ( keys %{$self->_get_singletons( )} )
  {
    $self->_release_singleton_by_name( $name );
  }

  $self->_drain_all_pools( );
}


##
# Protected
##

sub _get_service
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );

  my $class = $self->_get_service_class_by_service_name( $name ) or
    throw Error::Simple( "Couldn't get class for service '$name'" );

  my $factory = $self->_get_service_factory_by_service_name( $name ) or
    throw Error::Simple( "Couldn't get factory for service '$name'" );

  my $namespace = $self->_get_namespace( ) or
    throw Error::Simple( "Couldn't get namespace" );

  my $service = $factory->new_instance( $class, $namespace ) or
    throw Error::Simple( "Couldn't get service for class '$class'" );

  $self->_get_services( )->{ $service } = undef;

  my $service_configuration = $self->_get_configuration( )->{ $name };

  $service_configuration->{ _GLOBAL_ } = $self->_get_configuration( );

  $service->configure( $service_configuration ) if
    $service->can( "configure" );

  $service->service( $self ) if $service->can( "service" );

  $service->initialize( ) if $service->can( "initialize" );

  return $service;
}


sub _release_singleton_by_name
{
  my ( $self, $name ) = @_;

  my $service = $self->_get_singletons( )->{ $name } or
    throw Error::Simple( "Couldn't get singleton service '$name'\n" );

  $self->_release_service( $service );

  delete $self->_get_singletons( )->{ $name };
}


sub _release_service
{
  my ( $self, $service ) = @_;
  assert( $service, "service" );
  $service->dispose( );
  delete $self->_get_services( )->{ $service };
}


##
# Private
##

sub _initialize_configuration
{
  my ( $self, $configuration_path ) = @_;
  assert( $configuration_path, "configuration_path" );
  my $configuration_reader = new Unto::Essex::ConfigurationParser( );
  my $configuration = $configuration_reader->read( $configuration_path ) or
    throw Error::Simple( "Couldn't read $configuration_path" );
  $self->_set_configuration( $configuration );
}


sub _initialize_service_map
{
  my ( $self ) = @_;
  my $conf = $self->_get_configuration( );
  my @services = @{$conf->{ 'services' }};
  my $service_map = { };
  foreach my $service ( @services )
  {
    my $name = $service->{ 'name' } || $service->{ 'class' } or
      throw Error::Simple( "No name found for service in configuration" );
    $service_map->{ $name } = $service;
  }
  $self->_set_service_map( $service_map );
}

sub _service_name_is_pooled
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );
  return $self->_get_pool_max_by_service_name( $name );
}


sub _service_name_is_singleton
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );
  my $singleton = $self->_get_service_map( )->{ $name }->{ 'singleton' };
  return ( defined $singleton && ( 
          ( uc $singleton ne 'FALSE' ) || ( ! $singleton ) ) );
}


sub _service_is_pooled
{
  my ( $self, $service ) = @_;
  assert( $service, "service" );
  return defined $self->_get_services( )->{ $service };
}


sub _service_is_singleton
{
  my ( $self, $service ) = @_;
  assert( $service, "service" );
  # TODO -- maintain a second map for this
  foreach my $singleton_service ( values %{$self->_get_singletons( )} )
  {
    return 1 if $service == $singleton_service;
  }
  return 0;
}

sub _get_pooled_service
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );

  my $pool = $self->_get_pool( $name );
  my $service = $pool->get( );
  $self->_get_services( )->{ $service } = $pool;
  return $service;
}


sub _get_singleton_service
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );

  my $service = $self->_get_singletons( )->{ $name };

  if ( not defined $service )
  {
    $service = $self->_get_service( $name ) or
      throw Error::Simple( "Couldn't get service for $name" );

    $self->_get_singletons( )->{ $name } = $service;
  }

  return $service;
}


sub _new_pool
{
  my ( $self, $name ) = @_;

  my $pool_max = $self->_get_pool_max_by_service_name( $name ) or
    throw Error::Simple( "Couldn't get pool max for service '$name'" );

  return new Unto::Essex::ServicePool( $self, $name, $pool_max );
}


sub _get_pool
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );
  if ( not exists $self->_get_pools( )->{ $name } )
  {
    $self->_get_pools( )->{ $name } = $self->_new_pool( $name );
  }
  return $self->_get_pools( )->{ $name };
}


sub _return_to_pool
{
  my ( $self, $service ) = @_;
  assert( $service, "service" );
  my $pool = $self->_get_services( )->{ $service } or
    throw Error::Simple( "Service $service isn't pooled" );
  $pool->put( $service );
  delete $self->_get_services( )->{ $service };
}

sub _get_service_class_by_service_name
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );
  my $class = $self->_get_service_map( )->{ $name }->{ 'class' } or
    throw Error::Simple( "Service for '$name' not found" );
  return $class;
}


sub _get_pool_max_by_service_name
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );
  return $self->_get_service_map( )->{ $name }->{ 'pool-max' };
}


sub _get_service_factory_by_service_name
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );
  my $factory_name = $self->_get_service_map( )->{ $name }->{ 'factory' } ||
   $self->_get_default_factory( $name );
  my $factory = $self->_get_factory_map( )->{ $factory_name };
  if ( not defined $factory )
  {
    no strict 'refs';
    eval "require $factory_name;";
    throw Error::Simple( $@ ) if $@;
    $factory = $factory_name->new( ) or
      throw Error::Simple( "Couldn't instantiate $factory_name" );
    use strict;
    $self->_get_factory_map( )->{ $factory_name } = $factory;
  }
  return $factory;
}

sub _get_default_factory
{
  my ( $self, $name ) = @_;
  assert( $name, "name" );

  return $self->_service_name_is_singleton( $name ) ?
    'Unto::Essex::SingletonFactory' :
    'Unto::Essex::SimpleFactory';
}


sub _drain_all_pools
{
  my ( $self ) = @_;

  foreach my $pool ( values %{$self->_get_pools( )} )
  {
    $pool->drain( );
  }
}


sub DESTROY
{
  my ( $self ) = @_;

  return unless $self and $self->_get_services( );

  foreach my $service ( keys %{$self->_get_services( )} )
  {
    print STDERR "WARN: Service $service never disposed.  Be sure to call " .
      "dispose on the service manager to drain all pools.\n";
  }
}

1;


=pod

=head1 NAME

Unto::Essex::ServiceManager -- control the lifecycle of services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
