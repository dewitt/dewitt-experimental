#!/usr/bin/perl -w

use strict;
use warnings FATAL => 'all';

##
# Main
##

use Apache::Test qw( plan ok have_lwp );
use Apache::TestRequest qw( GET );
use Apache::TestUtil;
use Apache::TestRunPerl;

plan( tests => 1 );

my $response = GET( '/essex/http-hello/Hello World' );
chomp( my $content = $response->content( ) );
ok( t_cmp( $content, 'Hello World' ) );


1;
