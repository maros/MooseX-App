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
        my @candidates = $meta->command_matching($first_argv);
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
            my $commands = $meta->app_commands;
            my $command_class = $commands->{$candidates[0]};
            
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
            }
            return $class->_initialize_command($candidates[0],%args);
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


1;
