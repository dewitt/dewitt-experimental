package Unto::Essex::SingletonFactory;

##
# Import
##

use strict;
use base qw( Unto::Essex::Object );
use Error;
use Unto::Essex::Assert qw( assert );

##
# Class variables
##
our $_instance_map = { };

##
# Public
##

sub new_instance
{
  my ( $self, $class, $namespace ) = @_;

  assert( $class, "class" );
  assert( $namespace, "namespace" );
  
  my $key = join( '::', $namespace, $class );

  my $instance = $_instance_map->{ $key };

  if ( not defined $instance )
  {
    no strict 'refs';
    eval "require $class;";
    throw Error::Simple( $@ ) if $@;
    $instance = $class->new( ) or
      throw Error::Simple( "Couldn't instantiate $class" );
    use strict;
    $_instance_map->{ $key } = $instance;
  }

  return $instance;
}

1;

=pod

=head1 NAME

Unto::Essex::SingletonFactory -- instantiate singletons services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut

