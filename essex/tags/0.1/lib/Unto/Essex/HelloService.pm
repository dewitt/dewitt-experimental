package Unto::Essex::HelloService;

##
# Imports
##

use strict;
use Unto::Essex::AbstractService;
use base qw( Unto::Essex::AbstractService );

##
# Properties
##

use property recycle_count => 'SCALAR';
use property initialize_count => 'SCALAR';


##
# Public
##

sub new
{
  my ( $proto ) = @_;
  my $class = ref( $proto ) || $proto;
  my $self  = $class->SUPER::new( );
  bless( $self, $class );
  $self->set_initialize_count( 0 );
  return $self;
}

sub initialize
{
  my ( $self ) = @_;
  $self->SUPER::initialize( );
  $self->set_recycle_count( 0 );
  $self->set_initialize_count( $self->get_initialize_count( ) + 1 );
}

sub say_hello
{
  my ( $self ) = @_;
#  $self->_log_debug( "Saying Hello" );
  return "Hello World!";
}

sub recycle
{
  my ( $self ) = @_;
  $self->set_recycle_count( $self->get_recycle_count( ) + 1 );
}

1;


=pod

=head1 NAME

Unto::Essex::HelloService -- demo service

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton <dewitt@unto.net>

=cut
