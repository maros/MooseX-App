# ============================================================================
package MooseX::App::Plugin::BashCompletion::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;
use MooseX::App::Plugin::BashCompletion::Command;

around 'commands' => sub {
    my ($orig,$self) = @_;
    
    my %commands = $self->$orig();
    $commands{bash_completion} = 'MooseX::App::Plugin::BashCompletion::Command';
    
    return %commands;
};

1;