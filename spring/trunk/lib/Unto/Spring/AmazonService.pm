package Unto::Spring::AmazonService;

use strict;
use base qw( Unto::Spring::AbstractService );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use Error;
use Unto::Essex::Assert qw( assert );
use Unto::Essex::TemplateToolkitService;

use constant CACHE_ENABLED => 1;
use constant AWS_SERVICE => 'AWSECommerceService';
use constant AWS_OPERATION => 'ItemSearch';
use constant AWS_RESPONSE_GROUP => 'Medium';
use constant AWS_URL => 'http://webservices.amazon.com/onca/xml?' .
  'Service={Service}&Operation={Operation}&ResponseGroup={ResponseGroup}&' .
  'SubscriptionId={SubscriptionId}&SearchIndex={SearchIndex}&' .
  'ItemPage={ItemPage}&Keywords={Keywords}' .
  '&Style={Style}&Version={Version}&Sort={Sort}';
use constant AWS_VERSION => '2005-02-23';


##
# Public
##


sub get_product_opensearch_description
{
  my ( $self, $request, $params ) = @_;

  if ( ( $request->param( 'format' ) eq 'list' ) ||  ( not defined $params->{ 'searchIndex' } ) )
  {
    $self->_print_opensearch_description_list( $request, $params );
  }
  else
  {
    $self->_print_product_opensearch_description( $request, $params );
  }
}



sub get_product_xml
{
  my ( $self, $request, $params ) = @_;

  my $content = $self->_get_product_xml_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Amazon product xml content" );

  $request->content_type( "text/xml" );

  print $content;
}


sub get_product_opensearch
{
  my ( $self, $request, $params ) = @_;

  my $content = $self->_get_product_opensearch_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Amazon product opensearch content." );

  $request->content_type( "text/xml" );

  print $content;
}


sub get_product_html
{
  my ( $self, $request, $params ) = @_;

  my $content = $self->_get_product_html_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Amazon product html content." );

  $request->content_type( "text/html" );

  print $content;
}


## 
# Private
##

sub _get_image_url
{
  my ( $self, $request, $search_index ) = @_;

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $image_dir = $site_info->{ 'project_root' } .
    '/htdocs/images/';

  return undef unless -d $image_dir;

  my $image_name = 'amazon_product_' . $search_index->{ 'short_name' } . '.gif';

  my $image_path = "$image_dir/$image_name";

  return undef unless -f $image_path;

  my $project_url = $site_info->{ 'project_url' } or
    throw Error::Simple( "Couldn't get project url" );

  my $image_url = "$project_url/static/images/$image_name";

  return $image_url;
}



sub _get_short_name
{
  my ( $self, $search_index ) = @_;
  return lc $search_index;
}


sub _get_search_index
{
  my ( $self, $request, $params ) = @_;

  my $name = $params->{ 'searchIndex' } or
    throw Error::Simple( "Couldn't get searchIndex from params" );

  my $search_index = $self->_get_conf_key( 'search-indexes' )->{ $name } or
    throw Error::Simple( "Couldn't find search index $name" );

  $search_index->{ 'name' } = $name;

  $search_index->{ 'short_name' } = lc $name;

  $search_index->{ 'image_url' } =
    $self->_get_image_url( $request, $search_index );

  return $search_index;
}


sub _get_aws_params
{
  my ( $self, $request, $params ) = @_;

  my $search_index = $self->_get_search_index( $request, $params ) or
    throw Error::Simple( "Couldn't get search index" );

  my $search_terms = $params->{ 'searchTerms' } or
    throw Error::Simple( "Couldn't get search terms" );

  my $aws_params = { };

  $aws_params->{ 'Service' } = AWS_SERVICE;
  $aws_params->{ 'Operation' } = AWS_OPERATION;
  $aws_params->{ 'ResponseGroup' } = AWS_RESPONSE_GROUP;
  $aws_params->{ 'SubscriptionId'} = $self->_get_subscription_id( $request );
  $aws_params->{ 'Version'} = AWS_VERSION;
  $aws_params->{ 'SearchIndex' } = $search_index->{ 'name' };
  $aws_params->{ 'ItemPage' } = $params->{ 'startPage' };
  $aws_params->{ 'Keywords' } =  $search_terms;
  $aws_params->{ 'Sort' } = $self->_get_sort_order( $request, $search_index );

  return $aws_params;
}


sub _get_sort_order
{
  my ( $self, $request, $search_index ) = @_;

  my $style = $request->param( 'style' ) || 'desc';

  if ( $style ne 'prod' )
  {
    return undef;
  }

  return $search_index->{ 'date-sort' };
}



sub _get_subscription_id
{
  my ( $self, $request ) = @_;

  throw Error::Simple( "Please set AwsSubscriptionId in httpd.conf" ) unless
    defined $request->dir_config( "AwsSubscriptionId" );

  return $request->dir_config( "AwsSubscriptionId" );
}


sub _get_osrss_style_url
{
  my ( $self, $request, $params ) = @_;

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $style = $request->param( 'style' ) || 'desc';

  if ( $style ne 'desc' && $style ne 'pric' && $style ne 'prod' )
  {
    throw Error::Simple( "Unknown style $style" );
  }

  my $project_url = $site_info->{ 'project_url' } or
    throw Error::Simple( "Couldn't get project URL" );

  my $osrss_style_url = "$project_url/static/xsl/aws2osrss-$style.xsl";

  $self->_log_debug( "Using style sheet $osrss_style_url" );

  return $osrss_style_url;
}


sub _print_opensearch_description_list
{
  my ( $self, $request, $params ) = @_;

  $request->content_type( 'text/html' );

  my $search_indexes = $self->_get_conf_key( 'search-indexes' );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $project_url = $site_info->{ 'project_url' } or
    throw Error::Simple( "Couldn't get project url" );

  print "<ul id=\"opensearch-descriptions\">\n";

  foreach my $search_index ( sort keys %{$search_indexes} )
  {
    my $url = "$project_url/amazon/product/opensearchdescription/$search_index";
    print "<li><a href=\"$url\">$url</a></li>\n";
  }

  print "</ul>\n";
}



sub _print_product_opensearch_description
{
  my ( $self, $request, $params ) = @_;

  my $search_index = $self->_get_search_index( $request, $params ) or
    throw Error::Simple( "Couldn't get search index" );

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $vars = { 'search_index' => $search_index,
               'site_info' => $site_info };

  $request->content_type( 'text/xml' );

  $template_service->process( 'amazon_product_opensearch_description.tmpl', $vars );

  $self->_release( $template_service );
}


sub _get_product_xml_content
{
  my ( $self, $request, $params ) = @_;

  my $aws_params = $self->_get_aws_params( $request, $params ) or
    throw Error::Simple( "Couldn't build aws params" );

  my $aws_url = $self->_substitute_parameters( AWS_URL, $aws_params ) or
    throw Error::Simple( "Couldn't build aws URL" );

  my $content = $self->_fetch_url( $aws_url ) or
    throw Error::Simple( "Couldn't get $aws_url" );

  return $content;
}


sub _get_product_opensearch_content
{
  my ( $self, $request, $params ) = @_;

  my $aws_params = $self->_get_aws_params( $request, $params ) or
    throw Error::Simple( "Couldn't build aws params" );

  $aws_params->{ 'Style' } = $self->_get_osrss_style_url($request, $params ) or
    throw Error::Simple( "Couldn't get OSRSS style" );

  my $aws_url = $self->_substitute_parameters( AWS_URL, $aws_params ) or
    throw Error::Simple( "Couldn't build aws URL" );

  my $content = $self->_fetch_url( $aws_url ) or
    throw Error::Simple( "Couldn't get $aws_url" );

  return $content;
}


sub _get_product_html_content
{
  my ( $self, $request, $params ) = @_;

  my $opensearch_content = $self->_get_product_opensearch_content( $request, $params ) or
    throw Error::Simple( "Couldn't get Amazon product opensearch content" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $xslt_filename = $site_info->{ 'project_root' } . '/htdocs/xsl/osrss2html.xsl';

  my $content = $self->_transform( $opensearch_content, $xslt_filename ) or
    throw Error::Simple( "Couldn't transform content" );

  return $content;
}


1;


=pod

=head1 NAME

Unto::Spring::AwsService -- make calls to Amazon's web services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
