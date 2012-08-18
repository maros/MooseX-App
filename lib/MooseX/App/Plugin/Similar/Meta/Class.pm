# ============================================================================
package MooseX::App::Plugin::Similar::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use Text::WagnerFischer qw(distance);

sub command_candidates {
    my ($self,$command) = @_;
    
    my $lc_command = lc($command);
    my $commands = $self->app_commands;
    
    # Exact match
    if (defined $commands->{$lc_command}) {
        return $command;
    # Fuzzy match
    } else {
        my @candidates;
        my $candidate_length = length($command);
        
        # Compare all commands to find matching candidates
        foreach my $command_name (keys %$commands) {
            my $candidate_substr = substr($command_name,0,$candidate_length);
            if ($lc_command eq $candidate_substr
                || distance($lc_command,$candidate_substr) <= 1) {
                push(@candidates,$command_name);
            }
        }
    }
}

1;