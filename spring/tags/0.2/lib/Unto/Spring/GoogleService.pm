package Unto::Spring::GoogleService;

use strict;
use base qw( Unto::Spring::AbstractService );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use XML::LibXSLT;

use property _site_info_data => 'HASH';

use constant GOOGLE_SOAP_URL => 'http://api.google.com/search/beta2';

use constant GOOGLE_SOAP_QUERY => <<END;
<?xml version='1.0' encoding='UTF-8'?>

<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3
.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema">
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

sub get_web_opensearch_description
{
  my ( $self, $request, $params ) = @_;

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $vars = { 'site_info' => $site_info };

  $request->content_type( 'text/xml' );

  $template_service->process( 'google_web_opensearch_description.tmpl', $vars );

  $self->_release( $template_service );
}


sub get_web_soap
{
  my ( $self, $request, $params ) = @_;

  my $google_web_params = $self->_get_google_web_params( $request, $params ) or
    throw Error::Simple( "Couldn't build google web params" );

  my $google_soap_query = $self->_substitute_variables( GOOGLE_SOAP_QUERY, $google_web_params ) or
    throw Error::Simple( "Couldn't build google soap query" );

  my $google_headers = [ "Content-Type", "text/xml" ];

  my $content = $self->_cached_post_url( GOOGLE_SOAP_URL, $google_headers, $google_soap_query ) or
    throw Error::Simple( "Couldn't post google soap query" );

  $request->content_type( "text/xml" );

  print $content;
}


sub get_web_opensearch
{
  my ( $self, $request, $params ) = @_;

  my $google_web_params = $self->_get_google_web_params( $request, $params ) or
    throw Error::Simple( "Couldn't build google web params" );

  my $google_soap_query = $self->_substitute_variables( GOOGLE_SOAP_QUERY, $google_web_params ) or
    throw Error::Simple( "Couldn't build google soap query" );

  my $google_headers = [ "Content-Type", "text/xml" ];

  my $content = $self->_cached_post_url( GOOGLE_SOAP_URL, $google_headers, $google_soap_query ) or
    throw Error::Simple( "Couldn't post google soap query" );

  my %xslt_params = ( 'searchTerms' => "'". $params->{ 'searchTerms' } . "'",
                      'itemsPerPage' => NUM_RESULTS );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/googlesoap2osrss.xsl';

  my $new_content = $self->_transform( $content, $xslt_filename, %xslt_params ) or
    throw Error::Simple( "Couldn't transform content" );

  $request->content_type( "text/xml" );

  print $new_content;
}



##
# Private
##


sub _get_google_web_params
{
  my ( $self, $request, $params ) = @_;

  my $google_web_params = { };

  $google_web_params->{ 'WebId' } = $self->_get_web_id( $request );
  $google_web_params->{ 'searchTerms' } = $params->{ 'searchTerms' };
  $google_web_params->{ 'startIndex' } = $self->_get_start_index( $request, $params );

  return $google_web_params;
}



sub _get_web_id
{
  my ( $self, $request ) = @_;

  my $web_id = $request->dir_config( "GoogleWebId" ) or
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
