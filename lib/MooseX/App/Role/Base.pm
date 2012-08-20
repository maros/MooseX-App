# ============================================================================
package MooseX::App::Role::Base;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use MooseX::App::Message::Envelope;
use List::Util qw(max);

sub new_with_command {
    my ($class,%args) = @_;
    
    my $meta = $class->meta;
    
    local @ARGV = @ARGV;
    my $first_argv = shift(@ARGV);
    
    # No args
    if (! defined $first_argv
        || $first_argv =~ m/^\s*$/
        || $first_argv =~ m/^-/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_message(
                header          => "Missing command",
                type            => "error",
            ),
            $meta->command_usage_global(),
        );
    # Requested help
    } elsif (lc($first_argv) =~ m/^-{0,2}?(help|h|\?|usage)$/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_usage_global(),
        );
    # Looks like a command
    } else {
        my $return = $meta->command_get($first_argv);
        
        # Nothing found
        if (blessed $return
            && $return->isa('MooseX::App::Message::Block')) {
            return MooseX::App::Message::Envelope->new(
                $return,
                $meta->command_usage_global(),
            );
        # One command found
        } else {
            my $command_class = $meta->app_commands->{$return};
            return $class->initialize_command($return,%args);
        }
    }
}


1;
