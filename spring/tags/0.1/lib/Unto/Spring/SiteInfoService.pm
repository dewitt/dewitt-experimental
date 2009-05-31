package Unto::Spring::SiteInfoService;

use base qw( Unto::Essex::AbstractService );
use Error;
use property _site_info => 'HASH';

# Includes:
#
#   site-name:    the short name of the website (i.e., "unto.net" )
#   project-root: the directory under which the project lives
#   project-url:  the fully qualified URL under which the project
#                 can be accessed.  Requires request.

##
# Public
##

sub initialize
{
  my ( $self ) = @_;

  $self->SUPER::initialize( );

  my $site_name = $self->_get_conf_key( 'site-name' ) or
    throw Error::Simple( "Couldn't get site-name from configuration" );

  my $project_root = $self->_get_conf_key( 'project-root' ) or
    throw Error::Simple( "Couldn't get project-root from configuration" );

  my $site_info = { 'site_name' => $site_name,
                    'project_root' => $project_root };

  $self->_set_site_info( $site_info );
}


sub get_site_info
{
  my ( $self, $request ) = @_;

  my $site_info = $self->_get_site_info( ) or
    throw Error::Simple( "Couldn't get site info hash" );

  if ( defined $request )
  {
    my $project_url = $request->construct_url( $request->location( ) ) or
      throw Error::Simple( "Couldn't build project URL" );

    $project_url =~ s/\/$//;

    $site_info->{ 'project_url' } = $project_url;
  }

  return $site_info;
}


1;

