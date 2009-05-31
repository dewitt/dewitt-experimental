package Unto::Essex::SimpleFactory;

##
# Imports
##

use strict;
use base qw( Unto::Essex::Object );
use Error;
use Unto::Essex::Assert qw( assert );

##
# Public
##

sub new_instance
{
  my ( $self, $class ) = @_;
  assert( $class, "class" );
  no strict 'refs';
  eval "require $class;";
  throw Error::Simple( $@ ) if $@;
  my $instance = $class->new( ) or
    throw Error::Simple( "Couldn't instantiate $class" );
  use strict;
  return $instance;
}

1;


=pod

=head1 NAME

Unto::Essex::SimpleFactory -- instantiate services

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton <dewitt@unto.net>

=cut

