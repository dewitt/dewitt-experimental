package Unto::Essex::StderrLogService;

##
# Imports
##

use base qw( Unto::Essex::AbstractService );

##
# Public
##

sub log_emerg
{
  my ( $self, $message ) = @_;
  $self->_log( "EMERG: $message" );
}

sub log_alert
{
  my ( $self, $message ) = @_;
  $self->_log( "ALERT: $message" );
}


sub log_crit
{
  my ( $self, $message ) = @_;
  $self->_log( "CRIT: $message" );
}



sub log_error
{
  my ( $self, $message ) = @_;
  $self->_log( "ERROR: $message" );
}


sub log_warn
{
  my ( $self, $message ) = @_;
  $self->_log( "WARN: $message" );
}


sub log_notice
{
  my ( $self, $message ) = @_;
  $self->_log( "NOTICE: $message" );
}



sub log_info
{
  my ( $self, $message ) = @_;
  $self->_log( "INFO: $message" );
}


sub log_debug
{
  my ( $self, $message ) = @_;
  $self->_log( "DEBUG: $message" );
}


sub _log
{
  my ( $self, $message ) = @_;
  print STDERR "$message\n";
}

1;


=pod

=head1 NAME

Unto::Essex::StderrLogService -- log to STDERR

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton <dewitt@unto.net>

=cut

