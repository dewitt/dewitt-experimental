package Unto::Essex::TemplateToolkitService;

use strict;

##
# Imports
##

use Template;
use Unto::Essex::Assert qw( assert );
use base qw( Unto::Essex::AbstractService );

##
# Main
##

sub process
{
  my ( $self, $input, $vars, $output ) = @_;

  assert( $input, "input" );
  assert( $vars, "vars" );

  my $config = {
      INTERPOLATE  => 1,               # expand "$var" in plain text
      POST_CHOMP   => 1,               # cleanup whitespace 
      EVAL_PERL    => 1,               # evaluate Perl code blocks
  };

  $config->{ 'OUTPUT' } = $output if defined $output;

  my $template = new Template( $config );

  $template->process( $input, $vars ) or
    throw Error::Simple( "Couldn't process template: " . $template->error( ) );
}

1;


=pod

=head1 NAME

Unto::Essex::TemplateToolkitService -- wrap template toolkit

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut
