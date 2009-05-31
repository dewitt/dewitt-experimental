#!/usr/bin/perl

use lib 'lib';
use Unto::Essex::Build;
use Apache::TestConfig;

##
# Edit these to create a project
##

# Enter your project name here.  One word, all lowercase.  E.g., 'delancey'.
my $PROJECT_NAME = '' or
  die( "You forgot to enter a \$PROJECT_NAME in Build.PL" );

# Enter your site name here.  E.g., 'unto.net'.
my $SITE_NAME = '' or
  die( "You forgot to enter a \$SITE_NAME in Build.PL" );

# Enter your Perl package name here.  E.g., 'Unto'.
my $PACKAGE = '' or
  die( "You forgot to enter a \$PACKAGE in Build.PL" );


##
# Default Build.  Everything after here is okay to leave alone.
##

my $config = Apache::Test::config( ) or
  die( "Couldn't get http config" );

my $httpd_basedir = $config->{ httpd_basedir } or
  die( "Couldn't get httpd basedir" );

my $installdir = $httpd_basedir . '/' . $PROJECT_NAME;

my $lib_installdir = $installdir . '/lib';

my $build = new Unto::Essex::Build
(
  module_name => ( $PACKAGE . '::' . ucfirst( $PROJECT_NAME ) ),
  project_name => $PROJECT_NAME,
  create_makefile_pl => 'passthrough',
  site_name => $SITE_NAME,
  license => 'perl',
  requires =>
  {
    'Unto::Essex'    => '0.10',
    'Apache2::RequestRec' => '2.0',
    'Apache::Test'        => '1.25',
    'Template'            => '2.14'
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
