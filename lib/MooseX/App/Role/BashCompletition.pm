# ============================================================================
package MooseX::App::Role::BashCompletition;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;

around 'initialize_command' => sub {
    my ($orig,$self,$command) = @_;
    
    if ($command eq 'bash_completition') {
        # TODO
    } else {
        return $self->$orig($command);
    }
};

1;