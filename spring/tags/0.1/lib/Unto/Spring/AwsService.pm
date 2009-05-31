package Unto::Spring::AwsService;

use strict;
use base qw( Unto::Essex::AbstractService );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use Error;
use Unto::Essex::Assert qw( assert );
use Unto::Essex::TemplateToolkitService;

use property _site_info_data => 'HASH';

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

sub get_aws
{
  my ( $self, $request, $params ) = @_;

  my $aws_params = $self->_get_aws_params( $request, $params ) or
    throw Error::Simple( "Couldn't build aws params" );

  my $aws_url = $self->_substitute_parameters( AWS_URL, $aws_params ) or
    throw Error::Simple( "Couldn't build aws URL" );

  $request->content_type( "text/xml" );

  my $content = $self->_fetch_url( $aws_url ) or
    throw Error::Simple( "Couldn't get $aws_url" );

  print $content;
}



sub get_osd_list
{
  my ( $self, $request, $params ) = @_;

  $request->content_type( 'text/plain' );

  my $search_indexes = $self->_get_conf_key( 'search-indexes' );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $project_url = $site_info->{ 'project_url' } or
    throw Error::Simple( "Couldn't get project url" );

  foreach my $search_index ( sort keys %{$search_indexes} )
  {
    print "$project_url/aws/osd/$search_index\n";
  }
}


sub get_osd
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

  $template_service->process( 'osd.tmpl', $vars );

  $self->_release( $template_service );
}


sub get_osrss
{
  my ( $self, $request, $params ) = @_;

  my $aws_params = $self->_get_aws_params( $request, $params ) or
    throw Error::Simple( "Couldn't build aws params" );

  $aws_params->{ 'Style' } = $self->_get_osrss_style_url($request, $params ) or
    throw Error::Simple( "Couldn't get OSRSS style" );

  my $aws_url = $self->_substitute_parameters( AWS_URL, $aws_params ) or
    throw Error::Simple( "Couldn't build aws URL" );

  $request->content_type( "text/xml" );

  my $content = $self->_fetch_url( $aws_url ) or
    throw Error::Simple( "Couldn't get $aws_url" );

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

  my $image_name = 'aws_' . $search_index->{ 'short_name' } . '.gif';

  my $image_path = "$image_dir/$image_name";

  return undef unless -f $image_path;

  my $project_url = $site_info->{ 'project_url' } or
    throw Error::Simple( "Couldn't get project url" );

  my $image_url = "$project_url/images/$image_name";

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


sub _get_site_info
{
  my ( $self, $request ) = @_;

  my $site_info = $self->_get_site_info_data( );

  if ( not defined $site_info )
  {
    my $site_info_service = $self->_lookup( 'site-info' ) or
      throw Error::Simple( "Couldn't lookup site info service" );

    $site_info = $site_info_service->get_site_info( $request ) or
      throw Error::Simple( "Couldn't get site info from service" );

    $self->_set_site_info_data( $site_info );

    $self->_release( $site_info_service );
  }

  return $site_info;
}

sub _substitute_parameters
{
  my ( $self, $source_url, $search_parameters_ref ) = @_;

  my $url = $source_url;

  $url =~ s/(\&?)(\w+)=\{(\w+)\}/
          defined $search_parameters_ref->{ $3 } ?
           "$1$2=" . $self->_validate( $search_parameters_ref->{ $3 } ): 
           '' /xge;

  return $url;
}

sub _validate
{
  my ( $self, $value ) = @_;

  if ( $value =~ m/[^\:\/\w\s\+\-\%\.]/g )
  {
    throw Error::Simple( "Invalid value '$value'" );
  }

  return $value;
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
  $aws_params->{ 'ItemPage' } = $request->param( 'startPage' );
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


sub _fetch_url
{
  my ( $self, $url ) = @_;

  my $url_service = $self->_lookup( 'url' ) or
    throw Error::Simple( "Couldn't get UrlService" );

  my $content = $url_service->fetch_url( $url ) or
    throw Error::Simple( "Couldn't fetch $url" );

  $self->_release( $url_service );

  return $content;
}


sub _get_cache
{
  my ( $self ) = @_;

  return undef unless CACHE_ENABLED;

  my $cache = $self->_lookup( 'cache' ) or
    throw Error::Simple( "Couldn't get cache" );

  return $cache;
}


sub _release_cache
{
  my ( $self, $cache ) = @_;

  $self->_release( 'cache' ) if defined $cache;
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


1;


=pod

=head1 NAME

Unto::Spring::AwsService -- make calls to Amazon's web services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
