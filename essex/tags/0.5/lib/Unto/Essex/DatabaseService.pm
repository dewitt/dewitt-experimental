package Unto::Essex::DatabaseService;

use strict;
use base qw( Unto::Essex::AbstractService );
use Error;
use DBI( );

use property _dbh => undef;


##
# Public
##

sub get_dbh
{
  my ( $self ) = @_;

  my $dbh = $self->_get_dbh( );

  if ( not defined $dbh )
  {
    my $datasource = $self->_get_datasource( ) or
      throw Error::Simple( "Couldn't get datasource" );
    my $username = $self->_get_username( ) or
      throw Error::Simple( "Couldn't get username" );
    my $auth = $self->_get_auth( ) or
      throw Error::Simple( "Couldn't get auth" );
    $self->_log_debug( "Connecting to $datasource as $username" );
    $dbh = DBI->connect( $datasource, $username, $auth ) or
      throw Error::Simple( "Couldn't connect to $datasource: ".$DBI::errstr );
    $self->_set_dbh( $dbh );
  }

  return $dbh;
}


sub dispose
{
  my ( $self ) = @_;

  my $dbh = $self->_get_dbh( );

  if ( defined $dbh )
  {
    $self->_log_debug( "Disconnecting from database" );
    $dbh->disconnect( ) or
      throw Error::Simple( "Couldn't disconnect: " . $DBI::errstr );
    $self->_set_dbh( undef );
  }

  $self->SUPER::dispose( );
}

##
# Private
##


sub _get_datasource
{
  my ( $self ) = @_;

  my $datasource = $self->_get_conf_key( 'datasource' ) ||
    $ENV{ 'ESSEX_DATABASE_DATASOURCE' } or
      die( "Couldn't get database datasource." );

  return $datasource;
}



sub _get_username
{
  my ( $self ) = @_;

  my $username = $self->_get_conf_key( 'username' ) ||
    $ENV{ 'ESSEX_DATABASE_USERNAME' } or
      die( "Couldn't get database username." );

  return $username;
}


sub _get_auth
{
  my ( $self ) = @_;

  my $auth = $self->_get_conf_key( 'auth' ) ||
    $ENV{ 'ESSEX_DATABASE_AUTH' } or
      die( "Couldn't get database auth." );

  return $auth;

}

1;


=pod

=head1 NAME

Unto::Essex::DatabaseService -- manage DBI connections

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
