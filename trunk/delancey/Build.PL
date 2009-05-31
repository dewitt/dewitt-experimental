#!/usr/bin/perl

use lib 'lib';
use Unto::Delancey::Build;
use Apache::TestConfig;

##
# Edit these to create a project
##

my $PROJECT_NAME = 'delancey' or
  die( "You forgot to enter a \$PROJECT_NAME in Build.PL" );

my $SITE_NAME = 'unto.net' or
  die( "You forgot to enter a \$SITE_NAME in Build.PL" );

my $PACKAGE = 'Unto' or
  die( "You forgot to enter a \$PACKAGE in Build.PL" );


##
# Default Build
##

my $config = Apache::Test::config( ) or
  die( "Couldn't get http config" );

my $httpd_basedir = $config->{ httpd_basedir } or
  die( "Couldn't get httpd basedir" );

my $installdir = $httpd_basedir . '/' . $PROJECT_NAME;

my $lib_installdir = $installdir . '/lib';

my $build = new Unto::Delancey::Build
(
  module_name => ( $PACKAGE . '::' . ucfirst( $PROJECT_NAME ) ),
  project_name => $PROJECT_NAME,
  create_makefile_pl => 'passthrough',
  compress_js => 0,
  site_name => $SITE_NAME,
  license => 'perl',
  requires =>
  {
    'Unto::Essex'    => '0.11',
    'Apache2::RequestRec' => '2.000002',
    'Apache::Test'        => '1.25',
    'Template'            => '2.14',
    'YAML'                => '',
    'Digest::MD5'         => '',
    'JSON'                => '',
    'XML::Dumper'         => '',
  },
  install_path => { lib  => $lib_installdir },
  data_dirs => [ 'conf', 'templates', 'htdocs', 'lib/startup.pl.in' ],
  data_installdir => $installdir,
); 


$build->create_build_script;

1;

##
# Copyright (C) 2005 DeWitt Clinton, All Rights Reserved
##
