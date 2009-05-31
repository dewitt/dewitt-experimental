package Unto::Delancey::DelanceyService;

##
# Imports
##

use strict;
use base qw( Unto::Essex::AbstractService );
use Apache2::Access;
use Apache2::Const -compile => qw( REDIRECT AUTH_REQUIRED );
use Apache2::Request;
use Apache2::RequestRec;
use Apache2::URI;
use CGI::Cookie;
use Data::Dumper;
use Digest::MD5 qw( md5_hex );
use Error qw( :try );
use HTTP::Date qw( time2str );
use JSON;
use Unto::Essex::UrlService;
use Unto::Essex::TemplateToolkitService;
use Unto::Essex::Assert qw( assert );
use XML::Dumper;
use YAML;


##
# Properties and Constants
##

our $CLAIM_HEADER = 'X-Delancey-Claim';

use property _site_info_data => 'HASH';

use constant COOKIE_EXPIRATION => '+3M';
use constant DELICIOUS_LIMIT => 100;
use constant DELICIOUS_JSON_FEED =>
  'http://del.icio.us/feeds/json/{username}/{tag}?count={count}&raw=1"';
use constant DELICIOUS_API =>
  'http://del.icio.us/api/posts/get&tag={tag}';


##
# SQL Statements
##

use constant SQL_CREATE_BOOKMARK =><<END;
  INSERT IGNORE
   INTO bookmarks ( username_hash, url_hash, count, shortname, last_clicked )
   VALUES( ?, ?, 0, ?, NOW( ) )
END

use constant SQL_INCREMENT_BOOKMARK =><<END;
  UPDATE bookmarks
   SET
    count = count + 1,
    last_clicked = NOW( )
   WHERE
    username_hash = ? AND
    url_hash = ?
END

use constant SQL_UPDATE_SHORTNAME =><<END;
  UPDATE bookmarks
   SET shortname = ?
   WHERE
    username_hash = ? AND
    url_hash = ?
END

use constant SQL_SELECT_BOOKMARKS =><<END;
 SELECT url_hash, count, shortname, UNIX_TIMESTAMP( last_clicked )
  FROM bookmarks
  WHERE username_hash = ?
  ORDER BY count DESC
  LIMIT 100
END

use constant SQL_CREATE_CLAIM =><<END;
 INSERT
  INTO claims ( username_hash, password_hash, claim_hash )
  VALUES( ?, ?, ? )
END

use constant SQL_COUNT_CLAIMS =><<END;
  SELECT count( * )
   FROM claims
   WHERE username_hash = ?
    AND claim_hash = ?
END

use constant SQL_EXPIRE_OLD_CLAIMS =><<END;
  DELETE FROM claims
   WHERE created < ( CURRENT_TIMESTAMP( ) - INTERVAL ? SECOND )
END

use constant SQL_DELETE_CLAIMS =><<END;
  DELETE FROM claims
   WHERE username_hash = ? AND claim_hash = ?
END

use constant SQL_DELETE_USER =><<END;
  DELETE FROM users
    WHERE username_hash = ?
END

use constant SQL_CREATE_USER =><<END;
  INSERT
    INTO users ( username_hash, password_hash )
    VALUES( ?, ? )
END

use constant SQL_SELECT_CLAIM =><<END;
  SELECT username_hash, password_hash, claim_hash
  FROM claims
  WHERE
    username_hash = ? AND
    claim_hash = ?
END

use constant SQL_SELECT_USER =><<END;
  SELECT username_hash, password_hash 
  FROM users
  WHERE username_hash = ?
END


##
# Public
##

sub get_redirect
{
  my ( $self, $request, $params ) = @_;

  $self->_redirect( $request, $self->_get_startpage_url( $request ) );
}


sub get_startpage
{
  my ( $self, $request, $params ) = @_;

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $vars = { 'server_time' => time( ),
               'site_info' => $site_info,
               'base_url', => $site_info->{ 'project_url' } };

  my $username = $params->{ 'username' };

  if ( $username )
  {
    $self->_validate_username( $username );
    $self->_set_cookie( $request, 'delancey-username', $username );
    $vars->{ 'username' } = $username;
  }

  my $tag = $params->{ 'tag' };

  if ( $tag )
  {
    $self->_validate_tag( $tag );
    $self->_set_cookie( $request, 'delancey-tag', $tag );
    $vars->{ 'tag' } = $tag;
  }

  $self->_add_page_expiration( $request );

  $request->content_type( 'text/html' );

  $template_service->process( 'delancey.tmpl', $vars );

  $self->_release( $template_service );
}


sub get_tags
{
  my ( $self, $request, $params ) = @_;

  my $username = $params->{ 'username' } or
    throw Error::Simple( "Username required" );

  $self->_validate_username( $username );

  my $username_hash = md5_hex( $username ) or
    throw Error::Simple( "Couldn't get username hash" );

  $self->_validate_hash( $username_hash );

  if ( !$self->_can_access( $request, $username_hash ) )
  {
    return $self->_deny_access( $request );
  }

  my $tag_list = $self->_get_tag_list( $request, $username ) or
    throw Error::Simple( "Couldn't get tag list for $username" );

  $self->_add_page_expiration( $request );

  $self->_print( $request, $tag_list );
}


sub get_bookmarks
{
  my ( $self, $request, $params ) = @_;

  my $username = $params->{ 'username' } or
    throw Error::Simple( "Username required" );

  $self->_validate_username( $username );

  my $username_hash = md5_hex( $username ) or
    throw Error::Simple( "Couldn't get username hash" );

  $self->_validate_hash( $username_hash );

  if ( !$self->_can_access( $request, $username_hash ) )
  {
    return $self->_deny_access( $request );
  }

  my $tag = $params->{ 'tag' } or
    throw Error::Simple( "Tag required" );

  $self->_validate_tag( $tag );

  my $bookmarks = $self->_get_bookmarks( $username, $tag ) or
    throw Error::Simple( "Couldn't get bookmarks for $username, $tag" );

  $self->_print( $request, $bookmarks );
}

sub post_increment
{
  my ( $self, $request, $params ) = @_;

  my $username_hash = $params->{ 'username_hash' } or
    throw Error::Simple( "Username hash required" );

  $self->_validate_hash( $username_hash );

  if ( !$self->_can_access( $request, $username_hash ) )
  {
    return $self->_deny_access( $request );
  }

  my $url_hash = $params->{ 'url_hash' } or
    throw Error::Simple( "URL hash required" );

  $self->_validate_hash( $url_hash );

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( SQL_CREATE_BOOKMARK ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash, $url_hash, undef ) or
    throw Error::Simple( $dbh->errstr );

  $sth = $dbh->prepare( SQL_INCREMENT_BOOKMARK ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash, $url_hash ) or
    throw Error::Simple( $dbh->errstr );

  $self->_release( $database_service );
}


sub post_shortname
{
  my ( $self, $request, $params ) = @_;

  my $username_hash = $params->{ 'username_hash' } or
    throw Error::Simple( "Username required" );

  $self->_validate_hash( $username_hash );

  if ( !$self->_can_access( $request, $username_hash ) )
  {
    return $self->_deny_access( $request );
  }

  my $url_hash = $params->{ 'url_hash' } or
    throw Error::Simple( "URL hash required" );

  $self->_validate_hash( $url_hash );

  my $shortname = $params->{ 'shortname' } || '';

  $self->_validate_shortname( $shortname );

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( SQL_CREATE_BOOKMARK ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash, $url_hash, $shortname ) or
    throw Error::Simple( $dbh->errstr );

  $sth = $dbh->prepare( SQL_UPDATE_SHORTNAME ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $shortname, $username_hash, $url_hash ) or
    throw Error::Simple( $dbh->errstr );

  $self->_release( $database_service );
}


sub choose_password
{
  my ( $self, $request, $params ) = @_;

  my $username = $params->{ 'username' } or
    throw Error::Simple( "Username required" );

  $self->_validate_username( $username );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $is_claimed = $self->_is_claimed( $request, $username );

  my $vars = { 'username' => $username,
               'is_claimed' => $is_claimed,
               'site_info' => $site_info };

  $request->content_type( 'text/html' );

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  $template_service->process( 'choose_password.tmpl', $vars );

  $self->_release( $template_service );
}

sub verify_claim
{
  my ( $self, $request, $params ) = @_;

  my $username = $params->{ 'username' } or
    throw Error::Simple( "Username required" );

  $self->_validate_username( $username );

  my $username_hash = md5_hex( $username ) or
    throw Error::Simple( "Couldn't get username hash" );

  $self->_validate_hash( $username_hash );

  my $password = $request->param( 'password' ) or
    throw Error::Simple( "Password required" );

  my $password_again = $request->param( 'password-again' ) or
    throw Error::Simple( "Password verification required" );

  $password eq $password_again or
    throw Error::Simple( "Passwords don't match" );

  my $password_hash = md5_hex( $password ) or
    throw Error::Simple( "Couldn't get password hash" );

  $self->_validate_hash( $password_hash );

  my $claim_hash = $self->_get_new_claim( ) or
    throw Error::Simple( "Couldn't get new claim" );

  $self->_validate_hash( $claim_hash );

  my $claim_url = $self->_get_claim_url( $request, $username, $claim_hash ) or
   throw new Error::Simple( "Couldn't get claim url" );

  $self->_store_claim( $username_hash, $password_hash, $claim_hash ) or
    throw new Error::Simple( "Couldn't store claim for $username" );

  $request->content_type( 'text/html' );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $vars = { 'username' => $username,
               'claim_hash' => $claim_hash,
               'claim_url' => $claim_url,
               'site_info' => $site_info };

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  $template_service->process( 'verify_password.tmpl', $vars );

  $self->_release( $template_service );
}

sub complete_claim
{
  my ( $self, $request, $params ) = @_;

  my $username = $params->{ 'username' } or
    throw Error::Simple( "Username required" );

  $self->_validate_username( $username );

  my $username_hash = md5_hex( $username ) or
    throw Error::Simple( "Couldn't get username hash" );

  $self->_validate_hash( $username_hash );

  my $claim_hash = $params->{ 'claim_hash' } or
    throw Error::Simple( "Claim hash required" );

  my $template = undef;

  $self->_expire_old_claims( ) or
    throw Error::Simple( "Couldn't expire old claims" );

  if ( $self->_claim_exists( $username_hash, $claim_hash ) &&
       $self->_claim_made_by_user( $request, $username, $claim_hash ) )
  {
    $self->_change_password( $request, $username_hash, $claim_hash ) or
      throw Error::Simple( "Could not change password" );

    $self->_delete_claims( $username_hash, $claim_hash ) or
      throw Error::Simple( "Could not delete claims for $username_hash" );

    $template = 'claim_success.tmpl';
  }
  else
  {
    $template = 'claim_failure.tmpl';
  }

  $request->content_type( 'text/html' );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $claim_url = $self->_get_claim_url( $request, $username, $claim_hash ) or
    throw Error::Simple( "Couldn't get claim url" );

  my $claim_url_hash = md5_hex( $claim_url ) or
    throw Error::Simple( "Couldn't get claim_url hash" );

  my $vars = { 'username' => $username,
               'claim_url_hash' => $claim_url_hash,
               'site_info' => $site_info };

  my $template_service = $self->_lookup( 'template' ) or
    throw Error::Simple( "Couldn't get template service" );

  $template_service->process( $template, $vars );

  $self->_release( $template_service );
}


##
# Private
##

sub _redirect
{
  my ( $self, $request, $url ) = @_;

  assert( $request, 'request' );
  assert( $url, 'url' );

  $request->headers_out->set( 'Location' => $url );
  $request->status( Apache2::Const::REDIRECT );
}

# Delicious bookmarks are in an array

sub _get_delicious_bookmarks
{
  my ( $self, $username, $tag, $no_cache ) = @_;

  assert( $username, 'username' );

  $tag = '' unless defined $tag;

  my $vars = { 'username' => $username,
               'tag' => $tag,
               'count' => DELICIOUS_LIMIT };

  my $url = $self->_substitute_variables( DELICIOUS_JSON_FEED, $vars ) or
    throw Error::Simple( "Couldn't build url" );

  my $url_service = $self->_lookup( 'url' ) or
    throw Error::Simple( "Couldn't lookup url service" );

  my $json = undef;

  try
  {
    $json = $no_cache ? 
      $url_service->fetch_url_no_cache( $url ) :
      $url_service->fetch_url( $url );
  }
  catch Error with
  {
    $self->_log_debug( "Couldn't fetch url $url" );
  }
  finally
  {
    $self->_release( $url_service );
  };

  if ( $json )
  {
    local $JSON::BareKey = 1;

    my $bookmarks = jsonToObj( $json );

    return $bookmarks;
  }
  else
  {
    return undef;
  }
}


# Delancey bookmarks are indexed by hash

sub _get_delancey_bookmarks
{
  my ( $self, $username, $tag ) = @_;

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $username_hash = md5_hex( $username ) or
    throw Error::Simple( "Couldn't get username hash" );

  $self->_validate_hash( $username_hash );

  my $sth = $dbh->prepare( SQL_SELECT_BOOKMARKS ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash ) or
    throw Error::Simple( $dbh->errstr );

  my $bookmarks = { };

  while (  my ( $url_hash, $count, $shortname, $last_clicked ) = $sth->fetchrow_array( ) )
  {
    next unless defined $url_hash and $url_hash;
    my $bookmark = { };
    $bookmark->{ 'c' } = $count if defined $count;
    $bookmark->{ 's' } = $shortname if defined $shortname and $shortname;
    $bookmark->{ 'l' } = $last_clicked if defined $last_clicked;
    $bookmarks->{ $url_hash } = $bookmark;
  }

  $self->_release( $database_service );

  return $bookmarks;
}


sub _compute_hashes
{
  my ( $self, $delicious_bookmarks ) = @_;

  foreach my $bookmark ( @$delicious_bookmarks )
  {
    next if defined $bookmark->{ 'h' };
    next unless defined $bookmark->{ 'u' };
    $bookmark->{ 'h' } = md5_hex( $bookmark->{ 'u' } );
  }

  return $delicious_bookmarks;
}


sub _merge_bookmarks
{
  my ( $self, $delicious_bookmarks, $delancey_bookmarks ) = @_;

  my $delicious_bookmarks = $self->_compute_hashes( $delicious_bookmarks ) or
    throw Error::Simple( "Couldn't computer hashes" );

  my $bookmarks = { };

  foreach my $delicious_bookmark ( @$delicious_bookmarks )
  {
    my $h = $delicious_bookmark->{ 'h' } or next;
    my $bookmark = { };
    $bookmark->{ 'h' } = $h;
    $bookmark->{ 'c' } = $delancey_bookmarks->{ $h }->{ 'c' } || 0;
    $bookmark->{ 's' } = $delancey_bookmarks->{ $h }->{ 's' } || '';
    $bookmark->{ 'l' } = $delancey_bookmarks->{ $h }->{ 'l' } || '';
    $bookmark->{ 'u' } = $delicious_bookmark->{ 'u' };
    $bookmark->{ 't' } = $delicious_bookmark->{ 't' };
    $bookmark->{ 'd' } = $delicious_bookmark->{ 'd' };
    $bookmarks->{ $h } = $bookmark;
  }

  return $bookmarks;
}


sub _sort_bookmarks
{
  my ( $self, $bookmarks ) = @_;

  my @sorted_bookmarks = sort
  {
    if ( $a->{ 'c' } == $b->{ 'c' } )
    {
      return $a->{ 'h' } cmp $b->{ 'h' };
    }
    else
    {
      return $b->{ 'c' } <=> $a->{ 'c' };
    }
  } @$bookmarks;

  return \@sorted_bookmarks;
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


sub _get_startpage_url
{
  my ( $self, $request ) = @_;

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  my $startpage = $site_info->{ 'project_url' } . '/start/';

  return $startpage;
}


sub _substitute_variables
{
  my ( $self, $template, $variables_ref ) = @_;

  my $result = $template;

  $result =~ s/\{(\w+)\}/
    defined $variables_ref->{ $1 } ?
    $self->_validate_variable( $variables_ref->{ $1 } ):
    '' /xge;

  return $result;
}


sub _validate_variable
{
  my ( $self, $variable ) = @_;

  if ( $variable =~ m/[^\:\/\w\s\+\-\%\.\@\,\+]/g )
  {
    throw Error::Simple( "Invalid variable '$variable'" );
  }

  return $variable;
}


sub _validate_username
{
  my ( $self, $username ) = @_;

  throw Error::Simple( "Invalid username '$username'" ) if
    length $username > 64;

  throw Error::Simple( "Invalid username '$username'" ) if
    $username =~ m/[^\w\.]/;
}


sub _validate_tag
{
  my ( $self, $tag ) = @_;

  throw Error::Simple( "Invalid tag '$tag'" ) if
    length $tag > 64;

  throw Error::Simple( "Invalid tag '$tag'" ) if
    $tag =~ m/[^\w\:\.\-\*\%\@\,\+]/;
}


sub _validate_hash
{
  my ( $self, $hash ) = @_;

  throw Error::Simple( "Invalid hash '$hash'" ) if
    length $hash != 32;

  throw Error::Simple( "Invalid hash '$hash'" ) if
    $hash =~ m/[^0-9a-fA-F]/;
}


sub _validate_shortname
{
  my ( $self, $shortname ) = @_;

  throw Error::Simple( "Invalid shortname '$shortname'" ) if
    length $shortname > 255;

#  throw Error::Simple( "Invalid shortname '$shortname'" ) if
#    $shortname =~ m/[]/;
}



sub _print
{
  my ( $self, $request, $hash_ref ) = @_;

  my $format = $request->param( 'format' ) || 'yml';

  if ( $format eq 'json' )
  {
    $self->_print_json( $request, $hash_ref );
  }
  elsif ( $format eq 'perl' )
  {
    $self->_print_perl( $request, $hash_ref );
  }
  elsif ( $format eq 'xml' )
  {
    $self->_print_xml( $request, $hash_ref );
  }
  elsif ( $format eq 'yml' )
  {
    $self->_print_yml( $request, $hash_ref );
  }
  else
  {
    $self->_print_xml( $request, $hash_ref );
  }
}


sub _print_yml
{
  my ( $self, $request, $hash_ref ) = @_;

  $request->content_type( 'text/plain' );

  print YAML::Dump( $hash_ref );
}


sub _print_xml
{
  my ( $self, $request, $hash_ref ) = @_;

  $request->content_type( 'text/xml' );

  print pl2xml( $hash_ref );
}


sub _print_perl
{
  my ( $self, $request, $hash_ref ) = @_;

  $request->content_type( 'application/x-perl' );

  print Dumper( $hash_ref );
}

sub _print_json
{
  my ( $self, $request, $hash_ref ) = @_;

  $request->content_type( 'application/x-javascript' );

  print objToJson( $hash_ref );

}


sub _get_request_parameter
{
  my ( $self, $key, $request, $params, $vars ) = @_;

  my $value;

  if ( $value = $params->{ $key } )
  {
    return $value;
  }
  elsif ( $value = $request->param( $key ) )
  {
    return $value;
  }
  elsif ( $value = $self->_get_cookie( $request, 'delancey-' . $key ) )
  {
    return $value;
  }
  else
  {
    return undef;
  }
}

sub _get_cookie
{
  my ( $self, $request, $key ) = @_;

  assert( $request, 'request' );
  assert( $key, 'key' );

  my %cookies = CGI::Cookie->fetch( $request ) or
    return undef;

  my $cookie = $cookies{ $key } or 
    return undef;

  return $cookie->value( );
}


sub _set_cookie
{
  my ( $self, $request, $key, $value ) = @_;

  assert( $request, 'request' );
  assert( $key, 'key' );

  my $cookie = new CGI::Cookie( -name    => $key,
                                -value   => $value,
                                -expires => COOKIE_EXPIRATION,
                                -path    =>  '/' );

  $request->headers_out->set( 'Set-Cookie' => $cookie );
}


sub _get_bookmarks
{
  my ( $self, $username, $tag ) = @_;

  my $delicious_bookmarks =
    $self->_get_delicious_bookmarks( $username, $tag ) or
      return undef;

  my $delancey_bookmarks =
    $self->_get_delancey_bookmarks( $username, $tag ) or
      return undef;

  my $bookmarks =
    $self->_merge_bookmarks( $delicious_bookmarks, $delancey_bookmarks ) or
      throw Error::Simple( "Couldn't merge bookmarks" );

  # temporary hack to get around a caching bug in del.icio.us

  delete $bookmarks->{ 'c6712998522f31711c0d8ecd04c0788e' };

  return $bookmarks;
}


sub _get_tag_list
{
  my ( $self, $request, $username ) = @_;

  my $delicious_bookmarks = $self->_get_delicious_bookmarks( $username ) or
    return undef;

  my $tags = { };

  foreach my $bookmark ( @$delicious_bookmarks )
  {
    my $bookmark_tags = $bookmark->{ 't' };
    foreach my $tag ( @$bookmark_tags )
    {
      $tags->{ lc( $tag ) }++;
    }
  }

  my @tag_list;

  foreach my $tag ( sort { $tags->{$b} <=> $tags->{$a} } keys %$tags )
  {
    push( @tag_list, { 't' => $tag, 'c' => $tags->{$tag} } );
  }

  return \@tag_list;
}


sub _add_page_expiration
{
  my ( $self, $request, $page_expiration ) = @_;

  assert( $request, "request" );

  if ( not defined $page_expiration )
  {
    $page_expiration = $self->_get_conf_key( 'page_expiration' );
  }

  if ( defined $page_expiration and $page_expiration )
  {
    $request->headers_out->set( 'Expires' =>
                                time2str( time( ) + $page_expiration ) );
  }
}

sub _get_new_claim
{
  my ( $self ) = @_;

  my $rand = int( rand( 2 << 30 ) ) or
    throw Error::Simple( "Couldn't generate random number." );

  my $claim = md5_hex( $rand ) or
    throw Error::Simple( "Couldn't create hex from random claim." );

  $self->_validate_hash( $claim );

  return $claim;
}

sub _store_claim
{
  my ( $self, $username_hash, $password_hash, $claim_hash ) = @_;

  $self->_validate_hash( $username_hash );
  $self->_validate_hash( $password_hash );
  $self->_validate_hash( $claim_hash );

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( SQL_CREATE_CLAIM ) or
   throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash, $password_hash, $claim_hash ) or
    throw Error::Simple( $dbh->errstr );

  $self->_release( $database_service );

  $self->_log_debug( "New claim inserted for $username_hash" );

  return 1;
}

# -1 means there is no claim
#  0 means there is no claim
#  1

sub _matches_claim
{

}


sub _expire_old_claims
{
  my  ( $self ) = @_;

  my $claim_expiration = $self->_get_conf_key( 'claim_expiration' ) or
    return;

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( SQL_EXPIRE_OLD_CLAIMS ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $claim_expiration ) or
    throw Error::Simple( $dbh->errstr );

  $self->_log_debug( "Old claims expired." );

  return 1;
}

sub _claim_made_by_user
{
  my ( $self, $request, $username, $claim_hash ) = @_;

  $self->_validate_username( $username );
  $self->_validate_hash( $claim_hash );

  my $bookmarks = $self->_get_delicious_bookmarks( $username, '', 1 ) or
    throw Error::Simple( "Couldn't get bookmarks for $username" );

  foreach my $bookmark ( @$bookmarks )
  {
    if ( $bookmark->{ 'u' } =~ /$claim_hash/ )
    {
      return 1;
    }
  }

  return 0;
}

sub _claim_exists
{
  my ( $self, $username_hash, $claim_hash ) = @_;

  $self->_validate_hash( $username_hash );
  $self->_validate_hash( $claim_hash );

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( SQL_COUNT_CLAIMS ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash, $claim_hash ) or
    throw Error::Simple( $dbh->errstr );

  my ( $count ) = $sth->fetchrow_array( );

  $self->_log_debug( "Count for $username_hash is $count." );

  return $count and $count > 0;
}

sub _change_password
{
  my ( $self, $request, $username_hash, $claim_hash ) = @_;

  assert( $request, 'request' );
  $self->_validate_hash( $username_hash );
  $self->_validate_hash( $claim_hash );

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( SQL_SELECT_CLAIM ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash, $claim_hash ) or
    throw Error::Simple( $dbh->errstr );

  my ( $username_hash_db, $password_hash, $claim_hash_db ) =
    $sth->fetchrow_array( );

  ( ( $username_hash eq $username_hash_db ) and
    ( $claim_hash eq $claim_hash_db ) ) or
   throw Error::Simple( "Database values don't match input" );

  $self->_validate_hash( $password_hash );

  $sth = $dbh->prepare( SQL_DELETE_USER ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash ) or
    throw Error::Simple( $dbh->errstr );

  $sth = $dbh->prepare( SQL_CREATE_USER ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash, $password_hash ) or
    throw Error::Simple( $dbh->errstr );

  $self->_log_debug( "Set password for $username_hash." );

  $self->_set_cookie( $request, 'delancey-password', $password_hash );

  return 1;
}

sub _delete_claims
{
  my ( $self, $username_hash, $claim_hash ) = @_;

  $self->_validate_hash( $username_hash );
  $self->_validate_hash( $claim_hash );

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( SQL_DELETE_CLAIMS ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash, $claim_hash ) or
    throw Error::Simple( $dbh->errstr );

  $self->_log_debug( "Deleted claims for $username_hash." );

  return 1;
}

sub _get_claim_url
{
  my ( $self, $request, $username, $claim_hash ) = @_;

  assert( $request, 'request' );
  assert( $username, 'username' );
  assert( $claim_hash, 'claim_hash' );
  $self->_validate_username( $username );
  $self->_validate_hash( $claim_hash );

  my $site_info = $self->_get_site_info( $request ) or
    throw Error::Simple( "Couldn't get site info" );

  return $site_info->{ 'project_url' } . 
   '/claim/complete/' .
   $username . 
   '/' .
   $claim_hash .
   '/';
}


sub _can_access
{
  my ( $self, $request, $resource_username_hash ) = @_;

  assert( $request, 'request' );
  assert( $resource_username_hash, 'resource_username_hash' );
  $self->_validate_hash( $resource_username_hash );

  my $resource_password_hash =
    $self->_get_password_hash( $request, $resource_username_hash );

  if ( !$resource_password_hash )
  {
    $request->headers_out->set( $CLAIM_HEADER => 'none' );
    $self->_log_debug( "No restrictions for $resource_username_hash." );
    return 1;
  }

  $request->headers_out->set( $CLAIM_HEADER => 'claimed' );

  my ( $request_password_hash ) = 
    $self->_get_cookie( $request, 'delancey-password' );

  if ( !$request_password_hash )
  {
    $request->headers_out->set( $CLAIM_HEADER => 'denied' );
    $self->_log_debug( "Accessed denied: No request password." );
    return 0;
  }
 
  if ( $request_password_hash != $resource_password_hash ) 
  {
    $request->headers_out->set( $CLAIM_HEADER => 'denied' );
    $self->_log_debug( "Accessed denied: Request password mismatch." );
    return 0;
  }

  $request->headers_out->set( $CLAIM_HEADER => 'accepted' );
  $self->_log_debug( "User $resource_username_hash validated succesfully." );
  return 1;
}

sub _get_password_hash
{
  my ( $self, $request, $username_hash ) = @_;

  assert( $request, 'request' );
  assert( $username_hash, 'username_hash' );
  $self->_validate_hash( $username_hash );

  my $database_service = $self->_lookup( 'database' ) or
    throw Error::Simple( "Couldn't get database service" );

  my $dbh = $database_service->get_dbh( ) or
    throw Error::Simple( "Couldn't get dbh" );

  my $sth = $dbh->prepare( SQL_SELECT_USER ) or
    throw Error::Simple( $dbh->errstr );

  $sth->execute( $username_hash ) or
    throw Error::Simple( $dbh->errstr );

  my ( $username_hash_db, $password_hash ) = $sth->fetchrow_array( );

  $self->_release( $database_service );

  return $password_hash;
}

sub _deny_access
{
  my ( $self, $request ) = @_;
  my $reason = $request->headers_out->get( $CLAIM_HEADER );
  if ( $reason )
  {
    $self->_print_json( $request, { $CLAIM_HEADER => $reason } );
  }

  if ( $reason eq 'denied' )
  {
    $request->headers_out->set( 'Cache-Control' => 'no-cache' );
    $request->headers_out->set( 'Pragma' => 'no-cache' );
  }

  return Apache2::Const::OK;
}

sub _is_claimed
{
  my ( $self, $request, $username ) = @_;
 
  assert( $request, 'request' );
  assert( $username, 'username' );

  $self->_validate_username( $username );

  my $username_hash = md5_hex( $username ) or
    throw Error::Simple( "Couldn't get username hash" );

  $self->_validate_hash( $username_hash );

  return $self->_get_password_hash( $request, $username_hash );
}


1;


=pod

=head1 NAME

Unto::Delancey::DelanceyService -- a web service to augment del.icio.us

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut

