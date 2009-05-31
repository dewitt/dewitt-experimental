package Unto::Spring::YahooService;

use strict;
use base qw( Unto::Spring::AbstractService );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use XML::LibXSLT;

use property _site_info_data => 'HASH';

use constant YAHOO_WEB_URL => 'http://api.search.yahoo.com/WebSearchService/V1/webSearch?' .
  'appid={ApplicationId}&query={searchTerms}&start={startIndex}';

use constant NUM_RESULTS => 10;

##
# Public
##

sub get_web_opensearch_description
{
  my ( $self, $request, $params ) = @_;

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $vars = { 'site_info' => $site_info };

  $request->content_type( 'text/xml' );

  $template_service->process( 'yahoo_web_opensearch_description.tmpl', $vars );

  $self->_release( $template_service );
}


sub get_web_xml
{
  my ( $self, $request, $params ) = @_;

  my $yahoo_web_params = $self->_get_yahoo_web_params( $request, $params ) or
    throw Error::Simple( "Couldn't build yahoo web params" );

  my $yahoo_web_url = $self->_substitute_parameters( YAHOO_WEB_URL, $yahoo_web_params ) or
    throw Error::Simple( "Couldn't build yahoo web URL" );

  my $content = $self->_fetch_url( $yahoo_web_url ) or
    throw Error::Simple( "Couldn't get $yahoo_web_url" );

  $request->content_type( "text/xml" );

  print $content;
}


sub get_web_opensearch
{
  my ( $self, $request, $params ) = @_;

  my $yahoo_web_params = $self->_get_yahoo_web_params( $request, $params ) or
    throw Error::Simple( "Couldn't build yahoo web params" );

  my $yahoo_web_url = $self->_substitute_parameters( YAHOO_WEB_URL, $yahoo_web_params ) or
    throw Error::Simple( "Couldn't build yahoo web URL" );

  $self->_log_debug( "Fetching $yahoo_web_url" );

  my $content = $self->_fetch_url( $yahoo_web_url ) or
    throw Error::Simple( "Couldn't get $yahoo_web_url" );

  my %xslt_params = ( 'searchTerms' => "'". $params->{ 'searchTerms' } . "'",
                      'itemsPerPage' => NUM_RESULTS );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/yahooweb2osrss.xsl';

  my $new_content = $self->_transform( $content, $xslt_filename, %xslt_params ) or
    throw Error::Simple( "Couldn't transform content" );

  $request->content_type( "text/xml" );

  print $new_content;
}



##
# Private
##


sub _get_yahoo_web_params
{
  my ( $self, $request, $params ) = @_;

  my $yahoo_web_params = { };
  
  $yahoo_web_params->{ 'ApplicationId' } = $self->_get_application_id( $request );
  $yahoo_web_params->{ 'searchTerms' } = $params->{ 'searchTerms' };
  $yahoo_web_params->{ 'startIndex' } = $self->_get_start_index( $request, $params );

  return $yahoo_web_params;
}



sub _get_application_id
{
  my ( $self, $request ) = @_;

#  my $application_id = $request->param( 'applicationId' ) || $request->dir_config( "YahooApplicationId" ) or
#    throw Error::Simple( "Please set YahooApplicationId in httpd.conf" );

  my $application_id = $request->dir_config( "YahooApplicationId" ) or
    throw Error::Simple( "Please set YahooApplicationId in httpd.conf" );

  return $application_id;
}


sub _get_start_index
{
  my ( $self, $request, $params ) = @_;

  my $start_page = $params->{ 'startPage' } || 1;

  return ( ( $start_page - 1 ) * NUM_RESULTS ) + 1;
}


1;



=pod

=head1 NAME

Unto::Spring::YahooService -- make calls to Yahoo's web services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
