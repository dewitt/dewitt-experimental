package property;

use Carp;
use strict;
use constant _GET_METHOD => 'get';
use constant _SET_METHOD => 'set';

# When this package is "used" the subsequent parameters will
# constitute a hash that defines each property

sub import
{
  my $class = shift;
  return unless @_;
  push( @_, undef ) if scalar @_ % 2;
  my %properties = @_;
  my $package = caller( );
  while ( my ( $property, $type ) = each %properties )
  {
    my ( $private ) = $property =~ s|^_||;
    _Insert_Set_Method( $package, $property, $private, $type );
    _Insert_Get_Method( $package, $property, $private );
  }
}


# This routine determines whether or not the properties should be
# typechecked, and inserts the appropriate setter accordingly

sub _Insert_Set_Method
{
  my ( $package, $key, $private, $type ) = @_;

  if ( $type )
  {
    _Insert_Typechecked_Set_Method( $package, $key, $private, $type );
  }
  else
  {
    _Insert_Non_Typechecked_Set_Method( $package, $key, $private );
  }
}


# This routine dynamically generates a type checking set method for a
# property and attaches it to a class' symbol table under the
# appropriate name.
#
# For example, if you call:
#
#   _Insert_Typechecked_Set_Method( 'TestObject', 'foo', 'SCALAR' )
#
# then the TestObject object class will be given a set_foo method
# which contains:
#
# {
#   my ( $self, $data_ref ) = @_;
#
#   my $actual = ref $data_ref || 'SCALAR';
#
#   ( ( $actual eq 'SCALAR' ) or ( UNIVERSAL::isa( $actual, 'SCALAR' ) ) ) or
#     confess( "Type '$actual' is not a 'SCALAR'" );
#
#   $self->{ 'foo' } = $data_ref;
# };

sub _Insert_Typechecked_Set_Method
{
  my ( $package, $key, $private, $type ) = @_;

  my $set_method_symbol =
    _Build_Symbol( $package, _SET_METHOD, $key, $private );

  return if defined &$set_method_symbol;

  no strict 'refs';

  *{$set_method_symbol} = sub
  {
    my ( $self, $data_ref ) = @_;

    my $actual = ref $data_ref || 'SCALAR';

    ( ( not defined $data_ref ) or 
      ( $actual eq $type ) or
      ( UNIVERSAL::isa( $actual, $type ) ) ) or
        confess( "Type '$actual' is not '$type'" );

    $self->{ $key } = $data_ref;
  };

  use strict;
}


# This routine dynamically generates a get method for a property
# and attaches it to a class' symbol table under the appropriate
# name.  For example, if you call:
#
#   _Insert_Get_Method( 'TestObject', 'foo' )
#
# Then the TestObject object package will be given a get_foo method
# which contains:
#
#   {
#     my ( $self ) = @_;
#     return $self->{ 'foo' };
#   }

sub _Insert_Get_Method
{
  my ( $package, $key, $private ) = @_;

  my $get_method_symbol = 
    _Build_Symbol( $package, _GET_METHOD, $key, $private );

  return if defined &$get_method_symbol;

  no strict 'refs';

  *{$get_method_symbol} = sub
  {
    my ( $self ) = @_;

    return $self->{ $key };
  };

  use strict;
}


# This routine dynamically generates a set method for a property and
# attaches it to a class symbol table under the appropriate name.
#
# For example, if you call:
#
#   _Insert_Non_Typechecked_Set_Method( 'TestObject', 'foo' )
#
# then the TestObject object package will be given a set_foo method
# which contains:
#
# {
#   my ( $self, $data_ref ) = @_;
#
#   $self->{ 'foo' } = $data_ref;
# };

sub _Insert_Non_Typechecked_Set_Method
{
  my ( $package, $key, $private ) = @_;

  my $set_method_symbol = 
    _Build_Symbol( $package, _SET_METHOD, $key, $private );

  return if defined &$set_method_symbol;

  no strict 'refs';

  *{$set_method_symbol} = sub
  {
    my ( $self, $data_ref ) = @_;

    $self->{ $key } = $data_ref;
  };

  use strict;
}

 
# this routine returns the name of the entry into the symbol table
# for a particular type of property accessor

sub _Build_Symbol
{
  my ( $package, $method_prefix, $key, $private ) = @_;

  $method_prefix = "_${method_prefix}" if $private;

  my $method = join ( '_', $method_prefix, $key );

  return join ( '::', $package, $method );
}

1;

=pod

=head1 NAME

property -- a Perl pragma-like module for property method generation

=head1 DESCRIPTION

The property module is used to automatically generate get and set methods
for a named member variable on a given class.  The property can be given
a type that is checked at runtime and must be matched in order for
the value to be set.

The property module is invoked by using the property module and specifying
which properties and types to generate.  The general form is:

  use property [name] => [type];

This will generate the get_[name] and set_[name] methods.

For example:

  use property first_name => 'SCALAR';
  use property cache => 'Cache::FileCache';

If a type is set and that type is not equal to "undef", then the value for
each set method will be checked each time the method is called.  

If the property name begins with an underscore, then the get and set
methods will be prefixed with an underscore, indicating private
property accessor methods.


=head1 EXAMPLE

  package MyObject;

  use property "foo" => 'SCALAR';
  use property "bar" => 'HASH';

  sub new
  {
    my ( $proto ) = @_;
    my $class = ref( $proto ) || $proto;
    my $self  = {};
    bless( $self, $class );
    return( $self );
  }

  1;

  my $o = new MyObject( );

  $o->set_foo( "Foo" );
  my $foo = $o->get_foo( );

  $o->set_bar( { a => 'b' } );
  my $a = $o->get_bar( )->{ a };

=head1 NOTES

A getter or setter can be overrided by the implementing class if
needed.  By default, the setter will place the property value in
$self->{ $key }.

=head1 AUTHOR

Author: DeWitt Clinton <dewitt@unto.net>

Copyright (C) 2005 DeWitt Clinton, All Rights Reserved

=cut

  
