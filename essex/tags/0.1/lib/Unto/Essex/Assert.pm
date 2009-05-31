package Unto::Essex::Assert;


##
# Imports
##

use base qw( Exporter );
use vars qw( @EXPORT_OK );
use Error;

@EXPORT_OK = qw( assert );

##
# Public
##

sub assert
{
  my ( $value, $message ) = @_;

  defined $value or
    fail( "Value undefined", $message );

  $value or
    fail( "Value is false", $message );
}


sub fail
{
  my ( $type, $message ) = @_;

  my @caller = caller( 1 );

  throw Error::Simple( "Assert Failed ($type)" .
                       ( defined $message ? ": $message" : '.' ) . 
                       ": called by $caller[0] line $caller[2] \n" );
}

1;


=pod

=head1 NAME

Unto::Essex::Assert -- assertion routines

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton <dewitt@unto.net>

=cut
