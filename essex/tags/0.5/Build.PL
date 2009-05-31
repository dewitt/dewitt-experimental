#!/usr/bin/perl

use Module::Build;
use File::Find qw( find );

my $build_pkg = eval { require Apache::TestMB } ? 
    'Apache::TestMB' : 'Module::Build';

my $build = $build_pkg->new
(
  module_name => 'Unto::Essex',
  create_makefile_pl => 'passthrough',
  license => 'perl',
  requires => 
  {
    'perl'           => '5.8',
    'Error'          => '0.15',
    'YAML'           => '0.39'
  },
  recommends =>
  {
    'Apache2::RequestRec' => '2.0',
    'Apache::Test'        => '1.25',
    'Template'            => '2.14',
    'DBI'                 => '1.40',
    'Cache::Cache'        => '1.04',
    'LWP'                 => '5.79',
    'XML::LibXSLT'        => '1.57',
  },
);


my %dependencies = 
(
  'Apache2::RequestRec' => [ 't/07_rest_dispatcher_apache.t' ],
  'Template'            => [ 't/08_template_toolkit.t' ],
  'DBI'                 => [ 't/10_database_service.t' ],
  'Cache::Cache'        => [ 't/11_cache_service.t' ],
  'LWP'                 => [ 't/13_url_service.t' ],
  'XML::LibXSLT'        => [ 't/14_xslt_service.t' ]
);


foreach my $module ( keys %dependencies )
{
  if ( !has_module( $module ) )
  {
    print STDERR "Module '$module' not found.  Removing downstream tests.\n";
    foreach my $old ( @{$dependencies{ $module }} )
    {
       my $new = $old . '.disabled';
       print STDERR "Renaming '$old' to '$new'\n";
       if ( -e $old )
       {
         rename( $old, $new ) or die( "Couldn't rename $old to $new: $!" );
       }
     }
  }
}


sub has_module
{
  my ( $module ) = @_;
  return ( eval "require $module"  && ! $@ );
}


$build->create_build_script;

##
# Copyright (C) 2005 DeWitt Clinton, All Rights Reserved
##
