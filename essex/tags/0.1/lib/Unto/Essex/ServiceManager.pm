package Unto::Essex::ServiceManager;

##
# Imports
##

use strict;
use base qw( Unto::Essex::Object );
use Unto::Essex::Assert qw( assert );
use Unto::Essex::ConfigurationParser;
use Unto::Essex::ServiceParser;
use Unto::Essex::ServicePool;
use Error;

##
# Properties
##

use property _factory_map => 'HASH';
use property _service_map => 'HASH';
use property _configuration => 'HASH';
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
  my ( $proto, $services_path, $configuration_path ) = @_;
  my $class = ref( $proto ) || $proto;
  my $self  = {};
  bless( $self, $class );
  assert( $services_path, "services_path" );
  assert( $configuration_path, "configuration_path" );
  $self->_initialize_service_map( $services_path );
  $self->_initialize_configuration( $configuration_path );
  $self->_set_factory_map( { } );
  $self->_set_pools( { } );
  $self->_set_services( { } );
  $self->_set_singletons( { } );
  return( $self );
}


sub has_service
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );
  return defined $self->_get_service_map( )->{ $role };
}


sub lookup
{
  my ( $self, $role ) = @_;

  assert( $role, "role" );

  if ( $self->_role_is_pooled( $role ) )
  {
    return $self->_get_pooled_service( $role );
  }
  elsif ( $self->_role_is_singleton( $role ) )
  {
    return $self->_get_singleton_service( $role );
  }
  else
  {
    return $self->_get_service( $role );
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

  $self->_drain_all_pools( );
}


##
# Protected
##

sub _get_service
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );

  my $class = $self->_get_class_for_role( $role ) or
    throw Error::Simple( "Couldn't get class for $role" );

  my $factory = $self->_get_factory_for_role( $role ) or
    throw Error::Simple( "Couldn't get factory for role $role" );

  my $service = $factory->new_instance( $class ) or
    throw Error::Simple( "Couldn't get service for class $class" );

  $service->configure( $self->_get_configuration( ) ) if
    $service->can( "configure" );

  $service->service( $self ) if $service->can( "service" );

  $service->initialize( ) if $service->can( "initialize" );

  $self->_get_services( )->{ $service } = undef;

  return $service;
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
  my ( $self, $services_path ) = @_;
  assert( $services_path, "services_path" );
  my $service_configuration_reader = new Unto::Essex::ServiceParser( );
  my @services = $service_configuration_reader->read( $services_path ) or
    throw Error::Simple( "Couldn't read $services_path" );
  my $service_map = { };
  foreach my $service ( @services )
  {
    my $role = $service->{ 'role' } || $service->{ 'class' } or
      throw Error::Simple( "No role found for service" );
    $service_map->{ $role } = $service;
  }
  $self->_set_service_map( $service_map );
}


sub _role_is_pooled
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );
  return $self->_get_pool_max_for_role( $role );
}


sub _role_is_singleton
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );
  my $singleton = $self->_get_service_map( )->{ $role }->{ 'singleton' };
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
  return grep( $service, values %{$self->_get_singletons( )} );
}

sub _get_pooled_service
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );

  my $pool = $self->_get_pool( $role );
  my $service = $pool->get( );
  $self->_get_services( )->{ $service } = $pool;
  return $service;
}


sub _get_singleton_service
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );

  my $service = $self->_get_singletons( )->{ $role };

  if ( not defined $service )
  {
    $service = $self->_get_service( $role ) or
      throw Error::Simple( "Couldn't get service for $role" );
    $self->_get_singletons( )->{ $role } = $service;
  }

  return $service;
}


sub _new_pool
{
  my ( $self, $role ) = @_;

  return
    new Unto::Essex::ServicePool( $self,
                                  $role,
                                  $self->_get_pool_max_for_role( $role ) );
}


sub _get_pool
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );
  if ( not exists $self->_get_pools( )->{ $role } )
  {
    $self->_get_pools( )->{ $role } = $self->_new_pool( $role );
  }
  return $self->_get_pools( )->{ $role };
}


sub _return_to_pool
{
  my ( $self, $service ) = @_;
  assert( $service, "service" );
  my $pool = $self->_get_services( )->{ $service } or
    throw Error::Simple( "Service $service isn't pooled" );
  $pool->put( $service );
  $self->_get_services( )->{ $service } = undef;
}

sub _get_class_for_role
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );
  my $class = $self->_get_service_map( )->{ $role }->{ 'class' } or
    throw Error::Simple( "Service for $role not found" );
  return $class;
}


sub _get_pool_max_for_role
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );
  return $self->_get_service_map( )->{ $role }->{ 'pool-max' };
}


sub _get_factory_for_role
{
  my ( $self, $role ) = @_;
  assert( $role, "role" );
  my $factory_name = $self->_get_service_map( )->{ $role }->{ 'factory' } ||
   $self->_get_default_factory( $role );
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
  my ( $self, $role ) = @_;
  assert( $role, "role" );

  return $self->_role_is_singleton( $role ) ? 
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

  foreach my $service ( values %{$self->_get_singletons( )} )
  {
    $self->_release_service( $service );
  }

  if ( ( scalar keys %{$self->_get_services( )} ) > 0 )
  {
    print STDERR "WARN: Some services never disposed.  Be sure to call " .
      "dispose on the service manager to drain all pools.\n";
  }
}

1;


=pod

=head1 NAME

Unto::Essex::ServiceManager -- control the lifecycle of services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton <dewitt@unto.net>

=cut
