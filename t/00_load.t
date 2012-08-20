# -*- perl -*-

# t/00_load.t - check module loading and create testing directory

use Test::Most tests => 32;

use_ok( 'MooseX::App' ); 
use_ok( 'MooseX::App::Command' );
use_ok( 'MooseX::App::Base' );
use_ok( 'MooseX::App::Common' );
#use_ok( 'MooseX::App::Role' ); # cannot test since it can only be loaded into a Moose::Role
use_ok( 'MooseX::App::Utils' );
use_ok( 'MooseX::App::Message::Block' );
use_ok( 'MooseX::App::Message::Envelope' );
use_ok( 'MooseX::App::Meta::Role::Attribute::Option' );
use_ok( 'MooseX::App::Meta::Role::Class::Base' );
use_ok( 'MooseX::App::Meta::Role::Class::Command' );
use_ok( 'MooseX::App::Plugin::BashCompletion' );
use_ok( 'MooseX::App::Plugin::BashCompletion::Command');
use_ok( 'MooseX::App::Plugin::BashCompletion::Meta::Class');
use_ok( 'MooseX::App::Plugin::Config' );
use_ok( 'MooseX::App::Plugin::Config::Meta::Class');
use_ok( 'MooseX::App::Plugin::Env' );
use_ok( 'MooseX::App::Plugin::Env::Meta::Class');
use_ok( 'MooseX::App::Plugin::Env::Meta::Attribute');
use_ok( 'MooseX::App::Plugin::Version' );
use_ok( 'MooseX::App::Plugin::Version::Command');
use_ok( 'MooseX::App::Plugin::Version::Meta::Class');
use_ok( 'MooseX::App::Utils');
use_ok( 'MooseX::App::Simple');
use_ok( 'MooseX::App::Exporter');
use_ok( 'MooseX::App::Role::Base');
use_ok( 'MooseX::App::Role::Common');
use_ok( 'MooseX::App::Role::Simple');

SKIP :{
    my $ok = eval {
        Class::MOP::load_class('Term::ANSIColor');
        use_ok( 'MooseX::App::Plugin::Color' );
        use_ok( 'MooseX::App::Message::BlockColor' );
        use_ok( 'MooseX::App::Plugin::Color::Meta::Class');
    };
    unless ($ok) {
        skip "Term::ANSIColor is not installed",3;
    }
}

SKIP :{
    my $ok = eval {
        Class::MOP::load_class('File::HomeDir');
        use_ok( 'MooseX::App::Plugin::ConfigHome' );
        use_ok( 'MooseX::App::Plugin::ConfigHome::Meta::Class');
    };
    unless ($ok) {
        skip "File::HomeDir is not installed",2;
    }
}
