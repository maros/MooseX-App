# ============================================================================
package MooseX::App::Role::Simple;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose::Role;


sub new_with_options {
    my ($self,%args) = @_;
    
    $self->_initialize_command($self,%args);
}

1;