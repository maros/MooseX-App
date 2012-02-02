# -*- perl -*-

# t/00_load.t - check module loading and create testing directory

use Test::More tests => 1;

use_ok('MooseX::App'); 
use_ok('MooseX::App::Utils'); 
use_ok('MooseX::App::Role'); 
use_ok('MooseX::App::Command'); 