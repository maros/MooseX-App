# ============================================================================
package MooseX::App::Base;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;
with qw(MooseX::Getopt);

use MooseX::App::Message::Envelope;
use List::Util qw(max);

sub new_with_command {
    my ($class,%args) = @_;
    
    my $meta = $class->meta;
    
    my $first_argv = shift(@ARGV);
    
    # No args
    if (! defined $first_argv
        || $first_argv =~ m/^\s*$/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_message(
                header          => "Missing command",
                type            => "error",
            ),
            $meta->command_usage_global(),
        );
    # Requested help
    } elsif (lc($first_argv) =~ m/^-{0,2}(help|h|\?|usage)$/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_usage_global(),
        );
    # Looks like a command
    } else {
        my @candidates = $meta->matching_commands($first_argv);
        # No candidates
        if (scalar @candidates == 0) {
            return MooseX::App::Message::Envelope->new(
                $meta->command_message(
                    header          => "Unknown command '$first_argv'",
                    type            => "error",
                ),
                $meta->command_usage_global(),
            );
        # One candidate
        } elsif (scalar @candidates == 1) {
            return $class->initialize_command($candidates[0],%args);
        # Multiple candidates
        } else {
            my $message = "Ambiguous command '$first_argv'\nWhich command did you mean?";
            return MooseX::App::Message::Envelope->new(
                $meta->command_message(
                    header          => $message,
                    type            => "error",
                    body            => MooseX::App::Utils::format_list(map { [ $_ ] } @candidates),
                ),
                $meta->command_usage_global(),
            );
        }
    }
}

sub initialize_command {
    my ($class,$command_name,%args) = @_;
    
    my $meta = $class->meta;
    
    my %commands = $meta->commands;
    my $command_class = $commands{$command_name};
    
    eval {
        Class::MOP::load_class($command_class);
    };
    if (my $error = $@) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_message(
                header          => $error,
                type            => "error",
            ),
            $meta->command_usage_global(),
        );
        return;
    }
    
    my $proto_result = $class->proto_command($command_class);
    
    # TODO return some kind of null class object
    return
        unless defined $proto_result;
    
    return $proto_result
        if (blessed($proto_result) && $proto_result->isa('MooseX::App::Message::Envelope'));
    
    if ($proto_result->{help}) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_usage_command($command_class),
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
            $error =~ s/\n.+//s;
            chomp $error;
            return MooseX::App::Message::Envelope->new(
                $meta->command_message(
                    header          => $error,
                    type            => "error",
                ),
                $meta->command_usage_command($command_class),
            );
        }
        # TODO exitval 0 ..  ok , 1 .. error, 2..fatal error
        return $command_object;
    }
}

sub proto_command {
    my ($class,$command_class) = @_;
    
    my $opt_parser = Getopt::Long::Parser->new( config => [ qw( no_auto_help pass_through ) ] );
    my $result = {};
    $opt_parser->getoptions(
        $class->proto_options($result)
    );
    return $result;
}

sub proto_options {
    my ($class,$result) = @_;
    
    $result->{help} = 0;
    return (
        "help|usage|?"      => \$result->{help},
    );
}



1;