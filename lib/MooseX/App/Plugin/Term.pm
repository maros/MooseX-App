# ============================================================================
package MooseX::App::Plugin::Term;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;
    
    return {
        class       => ['MooseX::App::Plugin::Term::Meta::Class'],
        attribute   => ['MooseX::App::Plugin::Term::Meta::Attribute'],
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Term - Allows to specify options/parameters via terminal prompts

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Term);

In your command class: 

 package MyApp::SomeCommand;
 use MooseX::App::Command;
 
 option 'some_option' => (
     is             => 'rw',
     isa            => 'Str',
     documentation  => 'Something'
     cmd_term       => 1,
 );
 
 sub run {
     my ($self) = @_;
     say "Some option is ".$self->some_option;
 }

In your shell

 bash$ myapp some_command
 Something (Optional):
 test
 
 Some option is test

=head1 DESCRIPTION

This plugin can prompt the user for missing options/parameters on the terminal

=cut


