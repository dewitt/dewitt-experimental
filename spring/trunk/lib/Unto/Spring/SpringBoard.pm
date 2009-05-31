package Unto::Spring::SpringBoard;

use strict;
use base qw( Unto::Spring::AbstractService );

sub get_springboard_html
{
  my ( $self, $request, $params ) = @_;

  
  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $vars = { 'site_info' => $site_info };

  $request->content_type( 'text/html' );

  $template_service->process( 'springboard.tmpl', $vars );

  $self->_release( $template_service );
}

sub get_opensearch_descriptions
{
  my ( $self, $request, $params ) = @_;

  my $url_service = $self->_lookup( 'url' ) or
    throw Error::Simple( "Couldn't get url service" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my @opensearch_descriptions;

  $request->content_type( 'text/html' );

  foreach my $path ( '/google/web/', '/yahoo/web/', '/amazon/product/' )
  {
    my $url = $site_info->{ 'project_url' } . $path . 'opensearchdescription?format=list';

    my $content = $url_service->fetch_url( $url ) or
      throw Error::Simple( "Couldn't fetch $url" );

    my @urls = $content =~ m/href="(.*?)"/gs;

    push( @opensearch_descriptions, @urls );
  }

  print "<ul id=\"opensearch-descriptions\">\n";

  foreach my $url ( sort @opensearch_descriptions )
  {
    print "<li><a href=\"$url\">$url</a></li>\n";
  }

  print "</ul>\n";

  $self->_release( $url_service );
}

1;
