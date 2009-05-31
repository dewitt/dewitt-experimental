#!/usr/bin/perl

use lib 'lib';
use Unto::Essex::Build;
use Apache::TestConfig;

my $config = Apache::Test::config( ) or
  die( "Couldn't get http config" );

my $httpd_basedir = $config->{ httpd_basedir } or
  die( "Couldn't get httpd basedir" );

my $spring_installdir = $httpd_basedir . '/spring';

my $spring_lib_installdir = $spring_installdir . '/lib';

my $build = new Unto::Essex::Build
(
  module_name => 'Unto::Spring',
  project_name => 'spring',
  create_makefile_pl => 'passthrough',
  site_name => 'unto.net',
  license => 'perl',
  requires =>
  {
    'Unto::Essex'    => '0.5',
    'Apache2::RequestRec' => '2.0',
    'Apache::Test'        => '1.25',
    'Template'            => '2.14'
  },
  install_path => { lib  => $spring_lib_installdir },
  data_dirs => [ 'conf', 'templates', 'htdocs', 'lib/startup.pl.in' ],
  data_installdir => $spring_installdir,
); 


$build->create_build_script;

1;

##
# Copyright (C) 2005 DeWitt Clinton, All Rights Reserved
##
