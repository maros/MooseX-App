# ============================================================================
package MooseX::App::Plugin::Env::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

around 'command_args' => sub {
    my ($orig,$self,$command_meta) = @_;
    
    my ($result,$errors) = $self->$orig($command_meta);
    
    foreach my $attribute ($self->command_usage_attributes($command_meta,'all')) {
        next
            unless $attribute->can('has_cmd_env')
            && $attribute->has_cmd_env;
        
        my $cmd_env = $attribute->cmd_env;
        
        if (exists $ENV{$cmd_env}
            && ! defined $result->{$attribute->name}) {
            $result->{$attribute->name} = $ENV{$cmd_env};
            my $error = $attribute->cmd_type_constraint_check($ENV{$cmd_env});
            if ($error) {
                push(@{$errors},
                    $self->command_message(
                        header          => "Invalid environment value for '".$cmd_env."'", # LOCALIZE
                        type            => "error",
                        body            => $error,
                    )
                );
            }
        }
    }
    
    return ($result,$errors);
};

1;