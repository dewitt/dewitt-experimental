package Unto::Essex::ConfigurationParser;

##
# Imports
##

use YAML qw( LoadFile );
use strict;
use base qw( Unto::Essex::Object );
use Unto::Essex::Assert qw( assert );
use Error;

##
# Public
##

sub read
{
  my ( $self, $filename ) = @_;
  assert( $filename, "filename" );
  -f $filename or
    throw Error::Simple( "Couldn't find $filename" );
  my ( $hashref, $arrayref, $string ) = LoadFile( $filename ) or
    throw Error::Simple( "Couldn't parse YAML $filename" );
  return $hashref;

}

1;


=pod

=head1 NAME

Unto::Essex::ConfigurationParser -- read a YAML conf file

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton <dewitt@unto.net>

=cut
