# ============================================================================
package MooseX::App::Plugin::Term::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use IO::Interactive qw(is_interactive);

around 'command_args' => sub {
    my ($orig,$self,$command_meta) = @_;
    
    my ($result,$errors) = $self->$orig($command_meta);
    
    if (scalar @{$errors} == 0
        && is_interactive()) {
        foreach my $attribute ($self->command_usage_attributes($command_meta,'all')) {
            next
                unless $attribute->can('cmd_term')
                && $attribute->cmd_term;
            
            if (! defined $result->{$attribute->name}) {
                my $return = $attribute->cmd_term_read();
                $result->{$attribute->name} = $return
                    if defined $return;
            }
        }
    }
    
    return ($result,$errors);
};

1;