#!/usr/bin/perl

use Module::Build;

my $build = Module::Build->new
(
  module_name => 'Unto::Essex',
  dist_version => '0.1',
  create_makefile_pl => 'passthrough',
  license => 'perl',
  requires => 
  {
    'perl'           => '5.8',
    'Error'          => '0.15',
    'YAML'           => '0.39'
  },
);

$build->create_build_script;
