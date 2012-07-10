# ============================================================================
package MooseX::App::Plugin::Env::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

around 'command_usage_attribute_tags' => sub {
    my $orig = shift;
    my ($self,$attrribute) = @_;
    
    my @tags = $self->$orig($attrribute);
    push(@tags,'Env: '.$attrribute->cmd_env)
        if $attrribute->can('has_cmd_env')
        && $attrribute->has_cmd_env;
   
    return @tags;
};

around 'proto_command' => sub {
    my ($orig,$self,$command_class) = @_;
    
    my $result = $self->$orig($command_class);
    
    foreach my $attribute ($self->command_usage_attributes_list($command_class->meta)) {
        next
            unless $attribute->can('has_cmd_env')
            && $attribute->has_cmd_env;
       
        my $cmd_env = $attribute->cmd_env;
       
        $result->{$attribute->name} ||= $ENV{$cmd_env}
            if (exists $ENV{$cmd_env});
        
    }
    
    return $result;
};

1;