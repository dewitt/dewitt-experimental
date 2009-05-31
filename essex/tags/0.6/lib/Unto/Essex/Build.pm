package Unto::Essex::Build;

use Apache::TestMB;
use base qw( Apache::TestMB );
use ExtUtils::Install;
use File::Find;
use File::Spec;


##
# Overridden methods
##

sub ACTION_build
{
  my ( $self ) = @_;
  $self->SUPER::ACTION_build( );

  foreach my $file ( $self->_get_data_dirs( ) )
  {
    $self->copy_if_modified( from => $file, 
                             to_dir => $self->_get_blib_installdir( ) );
  }

  local %VARS;
  $VARS{ 'ServerRoot' } = $self->_get_server_root( );
  $VARS{ 'ProjectRoot' } = $self->_get_project_root( );
  $VARS{ 'ProjectName' } = $self->_get_project_name( );
  $VARS{ 'SiteName' } = $self->_get_site_name( );
  local $VAR_REGEX = join( '|', keys %VARS );
  find( \&_substitute_and_rename, $self->_get_blib_installdir( ) );
}

sub ACTION_fakeinstall
{
  my ( $self ) = @_;
  $self->SUPER::ACTION_fakeinstall( );
  ExtUtils::Install::install( $self->_get_install_map( ), 1, 1, 0 );
}


sub ACTION_install
{
  my ( $self ) = @_;
  $self->SUPER::ACTION_install( );
  ExtUtils::Install::install( $self->_get_install_map( ), 1, 0, 0 );
  find( \&_make_public, $self->_get_data_installdir( ) );

  print "Add the following to your httpd.conf:\n\n";
  print "   Include " . $self->_get_project_root( ) . "/conf/httpd.conf\n\n";
  print "And restart your server\n";
}


##
# Private
##

sub _get_server_root
{
  my ( $self ) = @_;

  my $server_root = Apache::Test::config( )->{ 'httpd_basedir' } or
    die( "Couldn't get httpd_basedir" );

  return $server_root;
}


sub _get_project_root
{
  my ( $self ) = @_;

  my $project_name = $self->{ 'properties' }->{ 'project_name' } or
    die( "Couldn't get project name" );

  return File::Spec->catfile( $self->_get_server_root( ), $project_name );
}


sub _get_project_name
{
  my ( $self ) = @_;

  my $project_name = $self->{ 'properties' }->{ 'project_name' } or
    die( "Couldn't get project name" );

  return $project_name;
}


sub _get_site_name
{
  my ( $self ) = @_;

  my $site_name = $self->{ 'properties' }->{ 'site_name' } or
    die( "Couldn't get site name" );

  return $site_name;
}


sub _get_blib_installdir
{
  my ( $self ) = @_;
  return File::Spec->catfile( 'blib', $self->_get_project_name( ) );
}

sub _get_data_installdir
{
  my ( $self ) = @_;
  return $self->{ 'properties' }{ 'data_installdir' };
}

sub _get_install_map
{
  my ( $self ) = @_;

  return { $self->_get_blib_installdir( ) => $self->_get_data_installdir( ),
           'read' => '' };
}

sub _get_data_dirs
{
  my ( $self ) = @_;

  local @data_dirs;

  find( \&_add_to_datadirs, @{$self->{ 'properties' }{ 'data_dirs' }} );
  
  return @data_dirs;
}

sub _add_to_datadirs
{
  return unless -f $_;
  return if $_ =~ m/~$/;
  return if $_ =~ m/^\#/;
  return if $File::Find::name =~ m/\.svn/;
  push ( @data_dirs, $File::Find::name );
}

sub _make_public
{
  my $filename = $File::Find::name;

  if ( -d $filename )
  {
    print "chmod 0755 $filename\n";
    chmod 0755, $filename or
      die( "Couldn't chmod $filename: $!" );
  }
  elsif ( -f $filename )
  {
    print "chmod 0644 $filename\n";
    chmod 0644, $filename or
      die( "Couldn't chmod $filename: $!" );
  }
}

sub _substitute_and_rename
{
  return unless -f $_;
  return unless $_ =~ m/\.in$/;
  
  my $old = $_;

  my ( $new ) = $old =~ m/^(.*?)\.in$/;

  print "Parameterizing $old into $new\n";

  open( OLD, $old ) or die( "Couldn't open $old: $!" );
  open( NEW, ">$new" ) or die( "Couldn't open $new for writing: $!" );
  while ( <OLD> )
  {
    $_ =~ s/\@($VAR_REGEX)\@/$VARS{$1}/g;
    print NEW $_;
  }
  close( OLD );
  close( NEW );

  -f $new or die( "Couldn't find $new" );

  unlink( $old ) or die( "Couldn't unlink $old" );
}

1;
