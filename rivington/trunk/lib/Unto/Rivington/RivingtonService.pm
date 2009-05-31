package Unto::Rivington::RivingtonService;

use strict;
use base qw( Unto::Essex::AbstractService );
use Apache2::Const -compile => qw( REDIRECT );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use Error;
use Unto::Essex::Assert qw( assert );

##
# Properties and constants
##

use property _site_info_data => 'HASH';
our @ITOBASE62C = ( (0..9), ('a'..'z'), ('A'..'Z') );
our %CTOBASE62I = reverse_map( @ITOBASE62C );


##
# Public
##

sub add_url
{
  my ( $self, $request, $params ) = @_;

  my $url = $request->param( 'url' ) or
    throw Error::Simple( "Couldn't get url parameter" );

  my $url = $self->_canonicalize( $url ) or
    throw Error::Simple( "Couldn't canonicalize URL" );

  my $hint = $request->param( 'hint' );

  my $short_url = $self->_get_short_url( $request, $url, $hint ) or
    throw Error::Simple( "Couldn't get short URL for $url" );

  if ( $request->param( 'format' ) eq 'xhtml' )
  {
     $request->content_type( 'text/xml' );

     print "<a href=\"$short_url\">$short_url</a>\n";
  }
  else
  {
    $request->content_type( 'text/plain' );

    print "$short_url\n";
  }
}



sub get_hint
{
  my ( $self, $request, $params ) = @_;

  my $url = $request->param( 'url' );

  my $hint = "";

  if ( $url )
  {
    $hint = $self->_get_hint( $url );
  }

  $request->content_type( 'text/plain' );

  print "$hint\n";
}


sub go_to_id
{
  my ( $self, $request, $params ) = @_;

  my $id = $params->{ 'id' } or
    throw Error::Simple( "Couldn't get id parameter" );

  $id = $self->_trim( $id ) or
    throw Error::Simple( "Id required" );

  $id !~ m/[^\w]/ or
    throw Error::Simple( "Invalid characters in id $id" );

  $id = base62decode( $id ) or
    throw Error::Simple( "Couldn't base62decode id $id" );

  $request->content_type('text/html');

  if ( my $url = $self->_get_url( $request, $id ) )
  {
    $self->_print_redirect( $request, $url );
  }
  else
  {
    $self->_print_spam( $request );
  }
}


sub _print_redirect
{
  my ( $self, $request, $url ) = @_;

  $request->headers_out->add( 'Location' => $url );

  $request->status( Apache2::Const::REDIRECT );
}

sub _print_spam
{
  my ( $self, $request ) = @_;

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $vars = { 'site_info' => $site_info };

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  $template_service->process( 'spam.tmpl', $vars );

  $self->_release( $template_service );
}

sub get_decoded
{
  my ( $self, $request, $params ) = @_;

  my $id = $params->{ 'id' } or
    throw Error::Simple( "Couldn't get id parameter" );

  $id = $self->_trim( $id ) or
    throw Error::Simple( "Id required" );

  $id !~ m/[^\w]/ or
    throw Error::Simple( "Invalid characters in id $id" );

  print STDERR "id before: $id\n";

  $id = base62decode( $id ) or
    throw Error::Simple( "Couldn't base62decode id $id" );

  print STDERR "id after: $id\n";

  my $url = $self->_get_url( $request, $id );

  $request->content_type('text/plain');

  print $url;
}

sub get_homepage
{
  my ( $self, $request, $params ) = @_;

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  $request->content_type( 'text/html' );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $url = $request->param( 'url' );

  my $hint = $request->param( 'hint' );

  my $vars = { 'site_info' => $site_info,
               'hint' => $hint };

  if ( $url )
  {
    $url = $self->_canonicalize( $url ) or
      throw Error::Simple( "Couldn't canonicalize URL" );

    my $short_url = $self->_get_short_url( $request, $url, $hint ) or
      throw Error::Simple( "Couldn't get short URL" );
    
    $vars->{ 'url' } = $url;
    $vars->{ 'short_url' } = $short_url;
  }

  $template_service->process( 'rivington.tmpl', $vars );

  $self->_release( $template_service );
}


sub get_dump
{
  my ( $self, $request, $params ) = @_;

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( "SELECT id, url, spam FROM urls" ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( ) or
    throw Error::Simple( $dbh->errstr );

  $request->content_type( 'text/plain' );

  while (  my ( $id, $url, $spam ) = $sth->fetchrow_array( ) )
  {
    $id = base62encode( $id );
    print $self->_build_short_url( $request, $id ) . " -> " .
      ( $spam ? '[spam] ' : '' ) . $url . "\n";
  }

  $self->_release( $database_service );
}

sub get_spam
{
  my ( $self, $request, $params ) = @_;

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( "SELECT id, url FROM urls WHERE spam = 1" ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( ) or
    throw Error::Simple( $dbh->errstr );

  $request->content_type( 'text/plain' );

  print "Spam URLs:\n\n";

  while (  my ( $id, $url ) = $sth->fetchrow_array( ) )
  {
    $id = base62encode( $id );

    print $self->_build_short_url( $request, $id ) . " -> " .
      $url . "\n";
  }

  $self->_release( $database_service );
}


##
# Private
##

sub _get_short_url
{
  my ( $self, $request, $url, $hint ) = @_;

  assert( $url, "url" );

  my $id = $self->_get_id( $request, $url ) or
    throw Error::Simple( "Couldn't get id from '$url'" );

  $hint = $self->_get_hint( $url ) unless $hint;

  $hint =~ s/[^\w\-]//g;

  if ( $hint =~ m/[^\w-]/ )
  {
    throw Error::Simple( "Illegal hint.  Alphanumeric only." );
  }

  return $self->_build_short_url( $request, $id, $hint );
}


sub _build_short_url
{
  my ( $self, $request, $id, $hint ) = @_;

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $project_path = $site_info->{ 'project_path' } or
    throw Error::Simple( "Couldn't get project path from site info" );

  my $site_name = $site_info->{ 'site_name' } or
    throw Error::Simple( "Couldn't get site name from site info" );

  my $short_url =  "http://$project_path.$site_name/$id" .
    ( $hint ? "?$hint" : '' );

  return $short_url;
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


sub _get_hint
{
  my ( $self, $url ) = @_;

  my $hint = lc $url;

  $hint =~ s/\w+:\/\///g;
  $hint =~ s/(www|home)\.//g;
  $hint =~ s/\.(net|com|org|info|co.uk)//g;
  $hint =~ s/\?.*?$//;
  $hint =~ s/\.\w+$//;
  $hint =~ s/[^\w]+/-/g;
  $hint =~ s/-+$//;
  $hint =~ s/^-+//;
  $hint =~ s/\b(\w+)-\1\b/$1/g;

  $hint = reverse $hint;

  while ( length $hint > 128 )
  {
    last unless $hint =~ s/(\w)\1+/\1/;
  }

  while ( length $hint > 128 )
  {
    last unless $hint =~ s/[aeiou]//;
  }

  $hint = reverse $hint;

  if ( length $hint > 128 )
  {
    $hint = substr( $hint, 0, 128 );
  }

  return $hint;
}

sub _get_id
{
  my ( $self, $request, $url ) = @_;

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( "SELECT id FROM urls WHERE url = ?" ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $url ) or
    throw Error::Simple( $dbh->errstr );

  my $id = undef;

  if ( my @row = $sth->fetchrow_array( ) )
  {
    $id = $row[0];
  }
  else
  {
    $sth = $dbh->prepare( "INSERT INTO urls ( url ) VALUES( ? )" ) or
      throw Error::Simple( $dbh->errstr );

    $sth->execute( $url ) or
      throw Error::Simple( $dbh->errstr );

    $id = $dbh->{ 'mysql_insertid' } or
      throw Error::Simple( "Couldn't get last insert id" );
  }

  $self->_release( $database_service );

  defined $id or
    throw Error::Simple( "Couldn't generate id" );

  $id = base62encode( $id ) or
    throw Error::Simple( "Couldn't base62 encode id" );

  $id !~ m/[^\w]/ or
    throw Error::Simple( "Invalid characters in id $id" );

  return $id;
}


sub _get_url
{
  my ( $self, $request, $id ) = @_;

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( "SELECT url, spam  FROM urls WHERE id = ?" ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $id ) or
    throw Error::Simple( $dbh->errstr );

  my ( $url, $spam ) = $sth->fetchrow_array( );

  $self->_release( $database_service );

  defined $url or
    throw Error::Simple( "Couldn't find id '$id'" );

  return $spam ? undef : $url;
}

sub _canonicalize
{
  my ( $self, $url ) = @_;

  $url or
    throw Error::Simple( "url required" );

  $url = $self->_trim( $url ) or
    throw Error::Simple( "url required" );

  $url = "http://$url" if $url !~ m/^\w+\:/;

  return $url;
}

sub _trim
{
  my ( $self, $string ) = @_;

  $string =~ s/^\s+//;
  $string =~ s/\s+//;

  return $string;
}


sub base62encode
{
  my ( $l ) = @_;
  my $s;
  do
  {
    $s = $ITOBASE62C[$l % 62 ] . $s;
    $l = int( $l / 62 );
  } while ( $l > 0 );

  return $s;
}

sub base62decode
{
  my ( $s ) = @_;
  my $l = 0;
  my $m = 1;
  map { $l += ( $CTOBASE62I{ $_ } * $m ); $m *= 62; } reverse( split( //, $s ) );
  return $l;
}

sub reverse_map
{
  my ( @list ) = @_;
  my %map;
  for ( my $i = 0; $i < scalar @list; $i++ ) { $map{$list[$i]} = $i; }
  return %map;
}

1;


=pod

=head1 NAME

  Unto::Rivington::RivingtonService -- a URL redirection service

=head1 AUTHOR

  Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
