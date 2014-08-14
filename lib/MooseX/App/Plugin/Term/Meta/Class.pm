# ============================================================================
package MooseX::App::Plugin::Term::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

around 'command_args' => sub {
    my ($orig,$self,$command_meta) = @_;
    
    my ($result,$errors) = $self->$orig($command_meta);
    
    if (scalar @{$errors} == 0) {
        foreach my $attribute ($self->command_usage_attributes($command_meta)) {
            next
                unless $attribute->can('has_cmd_term')
                && $attribute->cmd_term;
            
            if (! defined $result->{$attribute->name}) {
                
                my $label = $attribute->cmd_term_label_full;
                #say $label;
                    
                # $attribute->cmd_is_bool
                # $attribute->has_type_constraint
                #  - Bool
                #  - Num
                #  - Float
                #  - Enum
                #  - Str/other
                
                
                
#                $result->{$attribute->name} = $ENV{$cmd_env};
#                my $error = $self->command_check_attribute($attribute,$ENV{$cmd_env});
#                push(@{$errors},$error)
#                    if $error;
            }
        }
    }
    
    return ($result,$errors);
};

1;