package Unto::Essex::BerkeleyDatabaseService;

use strict;
use base qw( Unto::Essex::AbstractService );
use Error;
use BerkeleyDB;
use Unto::Essex::Assert qw( assert );

use property _bdb_hash => 'HASH';

##
# Public
##

sub get_database_hash
{
  my ( $self, $filename ) = @_;

  my $hash = $self->_get_bdb_hash( );

  if ( not defined $hash ) 
  {
    $hash = { };
    $filename = $self->_get_filename_from_conf( ) if not defined $filename;
    assert( $filename, 'filename' );
    my $options = { -Filename => $filename, -Flags => DB_CREATE };
    tie( %$hash, "BerkeleyDB::Hash", $options ) or
      throw Error::Simple( "Couldn't open file $filename: $!" .
                           "$BerkeleyDB::Error\n" );
    $self->_set_bdb_hash( $hash );
  }

  return $hash;
}


##
# Private
##

sub _get_filename_from_conf
{
  my ( $self )  = @_;

  my $filename = $self->_get_conf_key( 'filename' );

  $filename or
    throw Error::Simple( '"filename" required for BerkeleyDatabaseService ' .
                         'configuration' );

  return $filename;
}

1;


=pod

=head1 NAME

Unto::Essex::BerkeleyDatabaseService -- manage BDB tied hashes

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
