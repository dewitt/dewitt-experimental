package Unto::Rivington::SiteInfoService;

use strict;
use base qw( Unto::Essex::AbstractService );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::URI;
use Error;
use property _site_info => 'HASH';

# Includes:
#
#   site-name:    the short name of the website (i.e., "unto.net" )
#   project-root: the directory under which the project lives
#   project-url:  the fully qualified URL under which the project
#                 can be accessed.  Requires request.

##
# Public
##

sub initialize
{
  my ( $self ) = @_;

  $self->SUPER::initialize( );

  my $site_name = $self->_get_conf_key( 'site-name' ) or
    throw Error::Simple( "Couldn't get site-name from configuration" );

  my $project_root = $self->_get_conf_key( 'project-root' ) or
    throw Error::Simple( "Couldn't get project-root from configuration" );

  my $project_name = $self->_get_conf_key( 'project-name' ) or
    throw Error::Simple( "Couldn't get project-name from configuration" );

  my $project_path = $self->_get_conf_key( 'project-path' ) or
    throw Error::Simple( "Couldn't get project-path from configuration" );

  my $site_info = { 'site_name' => $site_name,
                    'project_name' => $project_name,
                    'project_path' => $project_path,
                    'project_root' => $project_root };

  $self->_set_site_info( $site_info );
}


sub get_site_info
{
  my ( $self, $request ) = @_;

  my $site_info = $self->_get_site_info( ) or
    throw Error::Simple( "Couldn't get site info hash" );

  if ( defined $request )
  {
    my $project_url = $request->construct_url( $request->location( ) ) or
      throw Error::Simple( "Couldn't build project URL" );

    $project_url =~ s/\/$//;

    $site_info->{ 'project_url' } = $project_url;
  }

  return $site_info;
}


sub get_api_html
{
  my ( $self, $request, $params ) = @_;

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't find template service" );

  my @dispatchers_data;

  foreach my $dispatcher ( @{$self->_get_dispatchers( )} )
  {
    push( @dispatchers_data, { 'path' => $dispatcher->{ 'path' },
                               'description' => $dispatcher->{ 'description' },
                               'methods' => $self->_get_methods( $dispatcher ),
                             } );
   }

  my @sorted_dispatchers_data = sort _path_sort @dispatchers_data;

  my $vars = { 'site_info' => $self->get_site_info( $request ),
               'dispatchers' => \@sorted_dispatchers_data };

  $request->content_type( 'text/html' );

  $template_service->process( 'api_html.tmpl', $vars );

  $self->_release( $template_service );
}


##
# Private
##

sub _get_global_configuration
{
  my ( $self ) = @_;

  return $self->_get_conf_key( '_GLOBAL_' );
}


sub _get_dispatchers
{
  my ( $self ) = @_;

  return $self->_get_global_configuration( )->{ 'dispatcher' }->{ 'dispatchers' };
}


sub _path_sort
{
  return $a->{ 'path' } cmp $b->{ 'path' };
}


sub _get_methods
{
  my ( $self, $dispatcher ) = @_;

  my @methods;
  
  map { push( @methods, uc $1 ) if m/^(\w+)-handler$/ } keys %$dispatcher;

  @methods = ( 'ALL' ) unless @methods;

  return \@methods;
}


1;


=pod

=head1 NAME

  Unto::Rivington::SiteInfoService -- meta information about an application

=head1 AUTHOR

  Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
