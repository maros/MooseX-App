# ============================================================================
package MooseX::App::Role::Common;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;
with 'MooseX::Getopt' => { 
    -excludes => [ 'help_flag', '_compute_getopt_attrs','new_with_options'] 
};

has 'help_flag' => (
    is              => 'ro', isa => 'Bool',
    traits          => ['AppOption','Getopt'],
    cmd_flag        => 'help',
    cmd_aliases     => [ qw(usage ?) ],
    documentation   => 'Prints this usage information.',
);

# Dirty hack to hide private attributes from MooseX-Getopt
sub _compute_getopt_attrs {
    my ($class) = @_;

    my @attrrs = sort { $a->insertion_order <=> $b->insertion_order }
        grep { $_->does('AppOption') } 
        $class->meta->get_all_attributes;

    return @attrrs;
}

sub _initialize_command {
    my ($self,$command_class,%args) = @_;
    
    my $meta         = $self->meta;
    my $command_meta = $command_class->meta;
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
            my $pa = $command_class->process_argv($proto_result);
            my %params = (                
                ARGV        => $pa->argv_copy,
                extra_argv  => $pa->extra_argv,
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