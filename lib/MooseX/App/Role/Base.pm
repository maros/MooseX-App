# ============================================================================
package MooseX::App::Role::Base;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

#has ARGV => (
#    is => 'rw', 
#    isa => 'ArrayRef', 
#);

sub initialize_command_class {
    my ($class,$command_class,%args) = @_;

    my $meta = $class->meta;
    
    Moose->throw_error('initialize_command_class is a class method')
        if blessed($class);
    
    my ($ok,$error) = Class::Load::try_load_class($command_class);
    unless ($ok) {
        Moose->throw_error($error);
    }
    
    my $command_meta = $command_class->meta || $meta;
    
    my $parsed_argv = MooseX::App::ParsedArgv->instance();
    #$parsed_argv->fuzzy($meta->app_fuzzy);
    $parsed_argv->hints($meta->command_parser_hints($command_meta));
    
    my ($proto_result,$proto_errors) = $meta->command_proto($command_meta);
    
    # TODO return some kind of null class object
    return
        unless defined $proto_result;
    
    my @errors = @{$proto_errors};

    # Return user-requested help
    if ($proto_result->{help_flag}) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_usage_command($command_class->meta),
        );
    }
    
    my ($result,$errors) = $meta->command_args($command_meta);
    push(@errors,@{$errors});
    
    my %params = (            
        %args,              # configs passed to new
        %{ $proto_result }, # config params
        %{ $result },       # params from CLI
    );
    
    # Check required values
    foreach my $attribute ($meta->command_usage_attributes($command_meta,[qw(option proto parameter)])) {
        if ($attribute->is_required
            && ! exists $params{$attribute->name}
            && ! $attribute->has_default) {
            push(@errors,
                $meta->command_message(
                    header          => "Required ".($attribute->cmd_type eq 'parameter' ? 'parameter':'option')." '".$attribute->cmd_name_primary."' missing", # LOCALIZE
                    type            => "error",
                )
            );
        }
    }
    
    if (scalar @errors) {
        return MooseX::App::Message::Envelope->new(
            @errors,
            $meta->command_usage_command($command_meta),
        );
    }
    
    my $command_object = $command_class->new(
        %params,
        extra_argv          => [ $parsed_argv->extra ],
    );
      
    if (scalar @errors) {
        return MooseX::App::Message::Envelope->new(
            @errors,
            $meta->command_usage_command($command_meta),
        );
    }
            
    return $command_object;
}


1;