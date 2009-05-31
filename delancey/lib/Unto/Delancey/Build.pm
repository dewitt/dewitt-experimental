package Unto::Delancey::Build;

use Unto::Essex::Build;
use base qw( Unto::Essex::Build );
use File::Find;

my $Rhino = 'tools/custom_rhino.jar';
my $_Java;

sub ACTION_build
{
  my ( $self ) = @_;
  $self->SUPER::ACTION_build( );
  if ( $self->{ 'properties' }->{ 'compress_js' } &&
       ( $_Java = `which java` ) && 
       ( -e $Rhino ) )
  {
    find( { wanted => \&_compress_js, no_chdir => 1 }, 'blib' );
  }
}

sub _compress_js
{
  return unless ( $File::Find::name =~ /\.js$/ );
  chomp( $_Java );
  print "Compressing $File::Find::name\n";
  my $old = "$File::Find::name";
  my $new = "$File::Find::name.compressed";
  `$_Java -jar $Rhino -c $old > $new`;
  if ( -s $new )
  {
    unlink( $old ) or die( "Couldn't unlink $old: $!" );
    rename( $new, $old ) or die( "Couldn't rename $new
: $1" );
  }
}



1;
