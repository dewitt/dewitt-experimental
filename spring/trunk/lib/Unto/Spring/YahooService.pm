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

use constant DEFAULT_SEARCH_TERMS => 'cat';

##
# Public
##

sub get_atom_results
{
  my ( $self, $request, $params ) = @_;

  my $yahoo_results = $self->get_native_search_results( $request, $params ) or
    throw Error::Simple( "Couldn't get native search results" );

  my $search_terms = $params->{ 'searchTerms' } || DEFAULT_SEARCH_TERMS;

  my %xslt_params = ( 'searchTerms' => '"' . $search_terms . '"',
                      'itemsPerPage' => NUM_RESULTS );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/yahooweb2atom.xsl';

  my $opensearch_results = $self->_transform( $yahoo_results, $xslt_filename, %xslt_params ) or
    throw Error::Simple( "Couldn't transform content" );

  return $opensearch_results;
}


sub get_native_search_results
{
  my ( $self, $request, $params ) = @_;

  my $search_terms = $params->{ 'searchTerms' } || DEFAULT_SEARCH_TERMS;

  my $search_params = { 'ApplicationId' => $self->_get_application_id( $request ),
                        'searchTerms' => $search_terms,
                        'startIndex' => $self->_get_start_index( $request, $params ) };

  my $yahoo_web_url = $self->_substitute_parameters( YAHOO_WEB_URL, $search_params ) or
    throw Error::Simple( "Couldn't build yahoo web URL" );

  my $yahoo_results = $self->_fetch_url( $yahoo_web_url ) or
    throw Error::Simple( "Couldn't get $yahoo_web_url" );

  return $yahoo_results;
}


sub print_description
{
  my ( $self, $request, $params ) = @_;

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $vars = { 'site_info' => $site_info };

  $request->content_type( 'application/opensearchdescription+xml' );

  $template_service->process( 'yahoo_web_opensearch_description.tmpl', $vars );

  $self->_release( $template_service );
}


##
# Private
##

sub _get_application_id
{
  my ( $self, $request ) = @_;

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
