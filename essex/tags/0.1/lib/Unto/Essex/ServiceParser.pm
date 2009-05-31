package Unto::Essex::ServiceParser;

##
# Imoprts
##

use strict;
use base qw( Unto::Essex::Object );
use Unto::Essex::Assert qw( assert );
use Error;
use YAML qw( LoadFile Dump );

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
  defined $hashref->{ 'services' } or
    throw Error::Simple( "No services found." );
  return @{$hashref->{ 'services' }};
}

1;


=pod

=head1 NAME

Unto::Essex::ServiceParser -- read in YAML service configurations

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton <dewitt@unto.net>

=cut
