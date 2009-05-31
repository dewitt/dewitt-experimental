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
  return "Hello World!";
}


sub do_get
{
  my ( $self, $request, $params ) = @_;
  return $self->say_hello( );
}


sub do_post
{
  my ( $self, $request, $params) = @_;

  my $salutation = $params->{ 'salutation' } or
    throw Error::Simple( "Couldn't find salutation" );

  return join( ":", $salutation, @{$params->{ '_UNMATCHED_' }} );

}


sub say_something
{
  my ( $self, $request, $params ) = @_;
  my $salutation = $params->{ 'salutation' } or
    throw Error::Simple( "Couldn't find salutation" );
  return $salutation;
}


sub say_something_different
{
  my ( $self, $request, $params ) = @_;
  my $salutation = $params->{ 'salutation' } or
    throw Error::Simple( "Couldn't find salutation" );
  return "different $salutation";
}


sub say_something_interesting
{
  my ( $self, $request, $params ) = @_;
  my $salutation = $params->{ 'salutation' } or
    throw Error::Simple( "Couldn't find salutation" );
  return "$salutation interesting";
}


sub recycle
{
  my ( $self ) = @_;
  $self->set_recycle_count( $self->get_recycle_count( ) + 1 );
}


sub http_salutation
{
  my ( $self, $request, $params ) = @_;
  $request->content_type( 'text/plain' );
  print $params->{ 'salutation' };
}


sub get_foo
{
  my ( $self ) = @_;
  return $self->_get_configuration( )->{ 'foo' };
}

sub get_global_foo
{
  my ( $self ) = @_;
  return $self->_get_configuration( )->{ _GLOBAL_ }->{ 'hello' }->{ 'foo' };
}

1;


=pod

=head1 NAME

Unto::Essex::HelloService -- demo service

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
