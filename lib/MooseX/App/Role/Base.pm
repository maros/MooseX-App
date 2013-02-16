# ============================================================================
package MooseX::App::Role::Base;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

has extra_argv => (
    is => 'rw', 
    isa => 'ArrayRef', 
);

#has ARGV => (
#    is => 'rw', 
#    isa => 'ArrayRef', 
#);

sub initialize_command_class {
    my ($class,$command_class,%args) = @_;

    my $meta         = $class->meta;
    
    Moose->throw_error('initialize_command_class is a class method')
        if blessed($class);
    
    my ($ok,$error) = Class::Load::try_load_class($command_class);
    unless ($ok) {
        Moose->throw_error($error);
#        return MooseX::App::Message::Envelope->new(
#            $meta->command_message(
#                header          => $error,
#                type            => "error",
#            ),
#            $meta->command_usage_global(),
#        );
    }

    my $command_meta = $command_class->meta || $meta;
    my $proto_result = $meta->proto_command($command_class);
    
    # TODO return some kind of null class object
    return
        unless defined $proto_result;
    
    return $proto_result
        if (blessed($proto_result) && $proto_result->isa('MooseX::App::Message::Envelope'));
    
    if ($proto_result->{help}) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_usage_command($command_class->meta),
        );
    } else {
        my $command_object = eval {
            Getopt::Long::Configure(($meta->app_fuzzy ? 'auto_abbrev' : 'no_auto_abbrev'));
            
            my $pa = $command_class->process_argv(%$proto_result,%args);
            
            #($meta->app_fuzzy ? 'auto_abbrev' : 'no_auto_abbrev')
            my %params = (                
                #ARGV        => $pa->argv_copy,
                extra_argv  => $parsed_argv->{extra},
                %args,                      # configs passed to new
                %{ $proto_result },         # config params
                %{ $pa->cli_params },       # params from CLI)
            );
            
            my $object = $command_class->new(%params);
            
            return $object;
        };
        if (my $error = $@) {
            chomp $error;
            $error =~ s/\n.+//s;
            $error =~ s/in call to \(eval\)$//;
            
            return MooseX::App::Message::Envelope->new(
                $meta->command_message(
                    header          => $error,
                    type            => "error",
                ),
                $meta->command_usage_command($command_meta),
            );
        }
        # TODO exitval 0 ..  ok , 1 .. error, 2..fatal error
        return $command_object;
    }   
}


1;