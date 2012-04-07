# -*- perl -*-

# t/00_load.t - check module loading and create testing directory

use Test::Most tests => 14;

use_ok( 'MooseX::App' ); 
use_ok( 'MooseX::App::Command' );
use_ok( 'MooseX::App::Base' );
#use_ok( 'MooseX::App::Role' ); # cannot test since it can only be loaded into a Moose::Role
use_ok( 'MooseX::App::Utils' );
use_ok( 'MooseX::App::Message::Block' );
use_ok( 'MooseX::App::Message::Envelope' );
use_ok( 'MooseX::App::Meta::Role::Attribute' );
use_ok( 'MooseX::App::Meta::Role::Class::Base' );
use_ok( 'MooseX::App::Meta::Role::Class::Command' );
use_ok( 'MooseX::App::Plugin::BashCompletion' );
use_ok( 'MooseX::App::Plugin::Config' );

SKIP :{
    my $ok = eval {
        Class::MOP::load_class('Term::ANSIColor');
        use_ok( 'MooseX::App::Plugin::Color' );
        use_ok( 'MooseX::App::Message::BlockColor' );
    };
    unless ($ok) {
        skip "Term::ANSIColor is not installed",2;
    }
}

SKIP :{
    my $ok = eval {
        Class::MOP::load_class('File::HomeDir');
        use_ok( 'MooseX::App::Plugin::ConfigHome' );
    };
    unless ($ok) {
        skip "File::HomeDir is not installed",1;
    }
}