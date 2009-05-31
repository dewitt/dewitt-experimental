package Unto::Essex::Object;

use strict;

sub new
{
  my ( $proto ) = @_;
  my $class = ref( $proto ) || $proto;
  my $self  = {};
  bless( $self, $class );
  return( $self );
}

1;

=pod

=head1 NAME

Unto::Essex::Object -- a trivial implementation of an object type

=head1 DESCRIPTION

The Object base class implements the new method in such a way that
it can be easily extended.

=head1 EXAMPLE

  package MyObject;

  use base qw( Unto::Essex::Object );

  1;

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut

  
