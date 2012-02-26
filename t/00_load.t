# -*- perl -*-

# t/00_load.t - check module loading and create testing directory

use Test::Most tests => 12;

use_ok( 'MooseX::App' ); 
use_ok( 'MooseX::App::Command' );
use_ok( 'MooseX::App::Message::Block' );
use_ok( 'MooseX::App::Message::Envelope' );
use_ok( 'MooseX::App::Meta::Role::Attribute' );
use_ok( 'MooseX::App::Meta::Role::Class::Base' );
use_ok( 'MooseX::App::Meta::Role::Class::Command' );
#use_ok( 'MooseX::App::Role' ); # cannot test since it can only be loaded into a Moose::Role
use_ok( 'MooseX::App::Role::Base' );
use_ok( 'MooseX::App::Role::Config' );
use_ok( 'MooseX::App::Utils' );

SKIP :{
    my $ok = eval {
        Class::MOP::load_class('Term::ANSIColor');
        use_ok( 'MooseX::App::Role::Color' );
        use_ok( 'MooseX::App::Message::BlockColor' );
    };
    unless ($ok) {
        skip "Term::ANSIColor is not installed",2;
    }
}