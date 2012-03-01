# ============================================================================
package MooseX::App::Meta::Role::BashCompletition;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;

around 'commands' => sub {
    my ($orig,$self) = @_;
    
    my %commands = $self->$orig();
    $commands{bash_completition} = 'MooseX::App::Command::BashCompletition';
    
    return %commands;
};

1;