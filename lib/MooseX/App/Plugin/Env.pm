# ============================================================================
package MooseX::App::Plugin::Env;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;
    
    return {
        class       => ['MooseX::App::Plugin::Env::Meta::Class'],
        attribute   => ['MooseX::App::Plugin::Env::Meta::Attribute'],
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Env - Read options from environment

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Env);

In your command class: 

 package MyApp::SomeCommand;
 use MooseX::App::Command;
 
 option 'some_option' => (
     is         => 'rw',
     isa        => 'Str',
     cmd_env    => 'SOME_OPTION',
 );
 
 sub run {
     my ($self) = @_;
     say "Some option is ".$self->some_option;
 }

In your shell

 bash$ export SOME_OPTION=test
 bash$ myapp some_command
 Some option is test
 
 bash$ SOME_OPTION=test
 bash$ myapp some_command --some_option override
 Some option is override

=head1 DESCRIPTION

This plugin can read options from the shell environment. Just add 'cmd_env' 
and a name (all uppercase and no spaces) to the options you wish to read from 
the environment.

=cut