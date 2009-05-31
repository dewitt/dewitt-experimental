package Unto::Spring::GoogleService;

use strict;
use base qw( Unto::Spring::AbstractService );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use XML::LibXSLT;

use property _site_info_data => 'HASH';

use constant DEFAULT_SEARCH_TERMS => 'cat';

use constant SOAP_URL => 'http://api.google.com/search/beta2';

use constant SOAP_QUERY => <<END;
<?xml version='1.0' encoding='UTF-8'?>

<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema">
  <SOAP-ENV:Body>
  <ns1:doGoogleSearch xmlns:ns1="urn:GoogleSearch"
         SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
      <key xsi:type="xsd:string">{WebId}</key>
      <q xsi:type="xsd:string">{searchTerms}</q>
      <start xsi:type="xsd:int">{startIndex}</start>
      <maxResults xsi:type="xsd:int">10</maxResults>
      <filter xsi:type="xsd:boolean">true</filter>
      <restrict xsi:type="xsd:string"></restrict>
      <safeSearch xsi:type="xsd:boolean">false</safeSearch>
      <lr xsi:type="xsd:string"></lr>
      <ie xsi:type="xsd:string">latin1</ie>
      <oe xsi:type="xsd:string">latin1</oe>
  </ns1:doGoogleSearch>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
END

use constant NUM_RESULTS => 10;


##
# Public
##

sub get_atom_results
{
  my ( $self, $request, $params ) = @_;

  my $soap_results = $self->get_native_search_results( $request, $params ) or
    throw Error::Simple( "Couldn't get native search results" );

  my %xslt_params = ( 'itemsPerPage' => NUM_RESULTS );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/googlesoap2atom.xsl';

  my $opensearch_results = $self->_transform( $soap_results, $xslt_filename, %xslt_params ) or
    throw Error::Simple( "Couldn't transform content" );

  return $opensearch_results;
}


sub get_native_search_results
{
  my ( $self, $request, $params ) = @_;

  my $search_terms = $params->{ 'searchTerms' } || DEFAULT_SEARCH_TERMS;

  my $search_params = { 'WebId' => $self->_get_web_id( $request ),
                        'searchTerms' => $search_terms,
                        'startIndex' => $self->_get_start_index( $request, $params ) };

  my $soap_query = $self->_substitute_variables( SOAP_QUERY, $search_params ) or
    throw Error::Simple( "Couldn't build soap query" );

  my $soap_headers = [ "Content-Type", "text/xml" ];

  my $soap_results = $self->_cached_post_url( SOAP_URL, $soap_headers, $soap_query ) or
    throw Error::Simple( "Couldn't post soap query" );

  return $soap_results;
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

  $template_service->process( 'google_web_opensearch_description.tmpl', $vars );

  $self->_release( $template_service );
}


##
# Private
##


sub _get_web_id
{
  my ( $self, $request ) = @_;

  my $web_id = $request->param( 'GoogleWebId' ) || $request->dir_config( "GoogleWebId" ) or
    throw Error::Simple( "Please set GoogleWebId in httpd.conf" );

  return $web_id;
}


sub _get_start_index
{
  my ( $self, $request, $params ) = @_;

  my $start_page = $params->{ 'startPage' } || 1;

  return ( ( $start_page - 1 ) * NUM_RESULTS );
}


1;



=pod

=head1 NAME

Unto::Spring::GoogleService -- make calls to Google's web services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
