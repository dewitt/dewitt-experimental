package Unto::Essex::XsltService;

use base qw( Unto::Essex::AbstractService );
use XML::LibXSLT;
use XML::LibXML;

##
# Public
##

sub transform
{
  my ( $self, $xml_data, $stylesheet_filename, %params ) = @_;

  my $xml_parser = new XML::LibXML( ) or
    throw Error::Simple( "Couldn't instantiate XML parser" );

  my $xml_doc = $xml_parser->parse_string( $xml_data ) or
    throw Error::Simple( "Couldn't parse xml data" );

  my $stylesheet_doc = $xml_parser->parse_file( $stylesheet_filename ) or
    throw Error::Simple( "Couldn't parse file $xslt_filename" );

  my $xslt_parser = new XML::LibXSLT( ) or
    throw Error::Simple( "Couldn't instantiate XSLT parser" );

  my $stylesheet = $xslt_parser->parse_stylesheet( $stylesheet_doc ) or
    throw Error::Simple( "Couldn't parse stylesheet $stylesheet_filename" );

  my $results = $stylesheet->transform( $xml_doc, %params ) or
    throw Error::Simple( "Couldn't transform xml data" );

  return $stylesheet->output_string( $results );
}


1;


=pod

=head1 NAME

Unto::Essex::XsltService -- A service for XSLT transformations

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
