package Unto::Spring::SearchService;

use strict;
use base qw( Unto::Spring::AbstractService );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use Error;
use Unto::Essex::Assert qw( assert );


##
# Constants
##

use constant VALID_SERVICES => qw( google yahoo msn );
use constant VALID_FORMATS => qw( atom rss osrss xhtml native description );

##
# Public
##

sub handle_get
{
  my ( $self, $request, $params ) = @_;

  my $service_name = $params->{ 'service' } || 'all';

  if ( ! grep( $service_name, VALID_SERVICES ) )
  {
    throw Error::Simple( "Invalid service '$service_name'" );
  }

  my $search_service = $self->_lookup( $service_name ) or
    throw Error::Simple( "Couldn't lookup search service '$service_name'" );

  my $format = $request->param( 'format' ) || 'xhtml';

  if ( ! grep( $format, VALID_FORMATS ) )
  {
    throw Error::Simple( "Invalid format '$format'" );
  }

  if ( $format eq 'description' )
  {
    $self->_handle_get_description( $search_service, $request, $params );
  }
  elsif ( $format eq 'osrss' || $format eq 'rss' )
  {
    $self->_handle_get_rss( $search_service, $request, $params );
  }
  elsif ( $format eq 'atom' )
  {
    $self->_handle_get_atom( $search_service, $request, $params );
  }
  elsif ( $format eq 'xhtml' )
  {
    $self->_handle_get_xhtml( $search_service, $request, $params );
  }
  elsif ( $format eq 'native' )
  {
    $self->_handle_get_native( $search_service, $request, $params );
  }
  else
  {
    throw Error::Simple( "Unknown format '$format'" );
  }
}


##
# Private
##

sub _handle_get_description
{
  my ( $self, $search_service, $request, $params ) = @_;

  $search_service->print_description( $request, $params ) or
    throw Error::Simple( "Couldn't print description" );
}


sub _handle_get_rss
{
  my ( $self, $search_service, $request, $params ) = @_;

  my $atom_results = $search_service->get_atom_results( $request, $params ) or
    throw Error::Simple( "Couldn't get results." );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/atom2rss.xsl';

  my %xslt_params = ( 'project-url' => '"' . $site_info->{ 'project_url' } . '"' );

  my $rss_results = $self->_transform( $atom_results, $xslt_filename, %xslt_params ) or
    throw Error::Simple( "Couldn't transform content" );

  $request->content_type( "text/xml" );

  print $rss_results;
}


sub _handle_get_atom
{
  my ( $self, $search_service, $request, $params ) = @_;

  my $atom_results = $search_service->get_atom_results( $request, $params ) or
    throw Error::Simple( "Couldn't get results." );

  $request->content_type( "application/atom+xml" );

  print $atom_results;
}


sub _handle_get_xhtml
{
  my ( $self, $search_service, $request, $params ) = @_;

  my $atom_results = $search_service->get_atom_results( $request, $params ) or
    throw Error::Simple( "Couldn't get results." );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/atom2xhtml.xsl';

  my %xslt_params = ( 'project-url' => '"' . $site_info->{ 'project_url' } . '"' );

  my $xhtml_results = $self->_transform( $atom_results, $xslt_filename, %xslt_params ) or
    throw Error::Simple( "Couldn't transform content" );

  $request->content_type( "text/html" );

  print $xhtml_results;
}


sub _handle_get_native
{
  my ( $self, $search_service, $request, $params ) = @_;

  my $native_results = $search_service->get_native_search_results( $request, $params ) or
    throw Error::Simple( "Couldn't get results." );

  $request->content_type( "text/xml" );

  print $native_results;
}

1;

