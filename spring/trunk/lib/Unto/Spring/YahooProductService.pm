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

use constant YAHOO_PRODUCT_URL => 'http://api.shopping.yahoo.com/ShoppingService/V1/productSearch?' .
  'appid={ApplicationId}&query={searchTerms}&start={startIndex}';

use constant NUM_RESULTS => 10;

##
# Public
##


sub get_web_opensearch_description
{
  my ( $self, $request, $params ) = @_;

  if ( $request->param( 'format' ) eq 'list' )
  {
    $self->_print_opensearch_description_list( $request, $params );
  }
  else
  {
    $self->_print_web_opensearch_description( $request, $params );
  }
}


sub get_product_opensearch_description
{
  my ( $self, $request, $params ) = @_;

  if ( $request->param( 'format' ) eq 'list' )
  {
    $self->_print_opensearch_description_list( $request, $params );
  }
  else
  {
    $self->_print_product_opensearch_description( $request, $params );
  }
}


sub get_web_xml
{
  my ( $self, $request, $params ) = @_;

  my $content = $self->_get_web_xml_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Yahoo web xml content" );

  $request->content_type( "text/xml" );

  print $content;
}


sub get_web_opensearch
{
  my ( $self, $request, $params ) = @_;

  my $content = $self->_get_web_opensearch_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Yahoo web opensearch content" );

  $request->content_type( "text/xml" );

  print $content;
}



sub get_product_opensearch
{
  my ( $self, $request, $params ) = @_;

  my $content = $self->_get_product_opensearch_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Yahoo product opensearch content" );

  $request->content_type( "text/xml" );

  print $content;
}


sub get_web_html
{
  my ( $self, $request, $params ) = @_;

  my $content = $self->_get_web_html_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Yahoo web HTML content" );

  $request->content_type( "text/html" );

  print $content;
}


sub get_product_xml
{
  my ( $self, $request, $params ) = @_;

  my $content = $self->_get_product_xml_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Yahoo product xml content" );

  $request->content_type( "text/xml" );

  print $content;
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



sub _get_yahoo_product_params
{
  my ( $self, $request, $params ) = @_;

  my $yahoo_product_params = { };
  
  $yahoo_product_params->{ 'ApplicationId' } = $self->_get_application_id( $request );
  $yahoo_product_params->{ 'searchTerms' } = $params->{ 'searchTerms' };
  $yahoo_product_params->{ 'startIndex' } = $self->_get_start_index( $request, $params );

  return $yahoo_product_params;
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


sub _print_opensearch_description_list
{
  my ( $self, $request, $params ) = @_;

  $request->content_type( 'text/html' );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $project_url = $site_info->{ 'project_url' } or
    throw Error::Simple( "Couldn't get project url" );

  my $web_url = "$project_url/yahoo/web/opensearchdescription/";
  my $product_url = "$project_url/yahoo/product/opensearchdescription/";

  print "<ul id=\"opensearch-descriptions\">\n";
  print "<li><a href=\"$web_url\">$web_url</a></li>\n";
  print "<li><a href=\"$product_url\">$product_url</a></li>\n";
  print "</ul>\n";
}


sub _print_web_opensearch_description
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



sub _print_product_opensearch_description
{
  my ( $self, $request, $params ) = @_;

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $vars = { 'site_info' => $site_info };

  $request->content_type( 'text/xml' );

  $template_service->process( 'yahoo_product_opensearch_description.tmpl', $vars );

  $self->_release( $template_service );
}



sub _get_web_xml_content
{
  my ( $self, $request, $params ) = @_;

  my $yahoo_web_params = $self->_get_yahoo_web_params( $request, $params ) or
    throw Error::Simple( "Couldn't build yahoo web params" );

  my $yahoo_web_url = $self->_substitute_parameters( YAHOO_WEB_URL, $yahoo_web_params ) or
    throw Error::Simple( "Couldn't build yahoo web URL" );

  my $content = $self->_fetch_url( $yahoo_web_url ) or
    throw Error::Simple( "Couldn't get $yahoo_web_url" );

  return $content;
}


sub _get_product_xml_content
{
  my ( $self, $request, $params ) = @_;

  my $yahoo_product_params = $self->_get_yahoo_product_params( $request, $params ) or
    throw Error::Simple( "Couldn't build yahoo product params" );

  my $yahoo_product_url = 
    $self->_substitute_parameters( YAHOO_PRODUCT_URL, $yahoo_product_params ) or
      throw Error::Simple( "Couldn't build yahoo product URL" );

  my $content = $self->_fetch_url( $yahoo_product_url ) or
    throw Error::Simple( "Couldn't get $yahoo_product_url" );

  return $content;
}



sub _get_web_opensearch_content
{
  my ( $self, $request, $params ) = @_;

  my $xml_content = $self->_get_web_xml_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Yahoo web XML content" );

  my %xslt_params = ( 'searchTerms' => "'". $params->{ 'searchTerms' } . "'",
                      'itemsPerPage' => NUM_RESULTS );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/yahooweb2osrss.xsl';

  my $content = $self->_transform( $xml_content, $xslt_filename, %xslt_params ) or
    throw Error::Simple( "Couldn't transform content" );

  return $content;
}


sub _get_product_opensearch_content
{
  my ( $self, $request, $params ) = @_;

  my $xml_content = $self->_get_product_xml_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Yahoo product XML content" );

  my %xslt_params = ( 'searchTerms' => "'". $params->{ 'searchTerms' } . "'",
                      'itemsPerPage' => NUM_RESULTS );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/yahooproduct2osrss.xsl';

  my $content = $self->_transform( $xml_content, $xslt_filename, %xslt_params ) or
    throw Error::Simple( "Couldn't transform content" );

  return $content;
}



sub _get_web_html_content
{
  my ( $self, $request, $params ) = @_;

  my $opensearch_content = $self->_get_web_opensearch_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Yahoo web opensearch content" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/osrss2xhtml.xsl';

  my $content = $self->_transform( $opensearch_content, $xslt_filename ) or
    throw Error::Simple( "Couldn't transform content" );

  return $content;
}


1;



=pod

=head1 NAME

Unto::Spring::YahooService -- make calls to Yahoo's web services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
