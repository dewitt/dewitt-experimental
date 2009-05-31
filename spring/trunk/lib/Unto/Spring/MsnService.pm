package Unto::Spring::MsnService;

use strict;
use base qw( Unto::Spring::AbstractService );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use XML::LibXSLT;

use property _site_info_data => 'HASH';

use constant DEFAULT_SEARCH_TERMS => 'cat';

use constant SOAP_URL => 'http://soap.search.msn.com/webservices.asmx';

use constant SOAP_QUERY => <<END;
<?xml version='1.0' encoding='UTF-8'?>

<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema">
    <SOAP-ENV:Body>
        <ns1:Search xmlns:ns1="http://schemas.microsoft.com/MSNSearch/2005/09/fex">
            <Request>
                <AppID xsi:type="xsd:string">{AppId}</AppID>
                <Query xsi:type="xsd:string">{searchTerms}</Query>
                <CultureInfo xsi:type="xsd:string">en-US</CultureInfo>
                <SafeSearch xsi:type="xsd:string">Off</SafeSearch>
                <Requests>
                    <SourceRequest>
                        <Source xsi:type="xsd:string">Web</Source>
                        <Offset xsi:type="xsd:int">{startIndex}</Offset>
                        <Count xsi:type="xsd:int">10</Count>
                        <ResultFields xsi:type="xsd:string">All</ResultFields>
                    </SourceRequest>
                </Requests>
            </Request>
        </ns1:Search>
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

  my $search_terms = $params->{ 'searchTerms' } || DEFAULT_SEARCH_TERMS;

  my %xslt_params = ( 'itemsPerPage' => NUM_RESULTS,
                      'searchTerms' => '"' . $search_terms . '"' );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/msnsoap2atom.xsl';

  my $opensearch_results = $self->_transform( $soap_results, $xslt_filename, %xslt_params ) or
    throw Error::Simple( "Couldn't transform content" );

  return $opensearch_results;
}

sub get_native_search_results
{
  my ( $self, $request, $params ) = @_;

  my $search_terms = $params->{ 'searchTerms' } || DEFAULT_SEARCH_TERMS;

  my $search_params = { 'AppId' => $self->_get_application_id( $request ),
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

  $template_service->process( 'msn_web_opensearch_description.tmpl', $vars );

  $self->_release( $template_service );
}


##
# Private
##


sub _get_application_id
{
  my ( $self, $request ) = @_;

  my $application_id = $request->dir_config( "MsnApplicationId" ) or
    throw Error::Simple( "Please set MsnApplicationId in httpd.conf" );

  return $application_id;
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

Unto::Spring::MsnService -- make calls to MSN's web services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
