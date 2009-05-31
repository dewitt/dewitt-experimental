package Unto::Essex::TemplateToolkitService;

use strict;

##
# Imports
##

use Template;
use Unto::Essex::Assert qw( assert );
use base qw( Unto::Essex::AbstractService );

use property _template => 'Template';

##
# Main
##

sub initialize
{
  my ( $self ) = @_;

  $self->SUPER::initialize( );

  my $config = {
      INTERPOLATE  => 1,               # expand "$var" in plain text
      POST_CHOMP   => 1,               # cleanup whitespace 
      EVAL_PERL    => 1,               # evaluate Perl code blocks
  };

  $config->{ 'INCLUDE_PATH' } = $self->_get_conf_key( 'basedir' ) if
    defined $self->_get_conf_key( 'basedir' );

  $config->{ 'COMPILE_DIR' } = $self->_get_conf_key( 'compile-dir' ) if
    defined $self->_get_conf_key( 'compile-dir' );

  my $template = new Template( $config ) or
    throw Error::Simple( "Couldn't instantiate template " . $Template::ERROR );

  $self->_set_template( $template );
}

sub process
{
  my ( $self, $input, $vars, $output ) = @_;

  assert( $input, "input" );
  assert( $vars, "vars" );

  $self->_get_template( )->process( $input, $vars, $output ) or
    throw Error::Simple( "Couldn't process template: " . 
                         $self->_get_template( )->error( ) );
}


1;


=pod

=head1 NAME

Unto::Essex::TemplateToolkitService -- wrap template toolkit

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
