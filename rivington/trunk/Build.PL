#!/usr/bin/perl

use lib 'lib';
use Unto::Essex::Build;
use Apache::TestConfig;

my $config = Apache::Test::config( ) or
  die( "Couldn't get http config" );

my $httpd_basedir = $config->{ httpd_basedir } or
  die( "Couldn't get httpd basedir" );

my $rivington_installdir = $httpd_basedir . '/rivington';

my $rivington_lib_installdir = $rivington_installdir . '/lib';

my $build = new Unto::Essex::Build
(
  module_name => 'Unto::Rivington',
  project_path => 'r',
  project_name => 'rivington',
  site_name => 'unto.net',
  create_makefile_pl => 'passthrough',
  license => 'perl',
  requires =>
  {
    'Unto::Essex'    => '0.9',
    'Apache2::RequestRec' => '2.0',
    'Apache::Test'        => '1.25',
    'Template'            => '2.14'
  },
  install_path => { lib  => $rivington_lib_installdir },
  data_dirs => [ 'conf', 'templates', 'htdocs', 'lib/startup.pl.in' ],
  data_installdir => $rivington_installdir,
);


$build->create_build_script;

1;

##
# Copyright (C) 2005 DeWitt Clinton, All Rights Reserved
##
