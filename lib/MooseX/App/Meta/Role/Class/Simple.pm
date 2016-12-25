# ============================================================================
package MooseX::App::Meta::Role::Class::Simple;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

around 'command_usage_header' => sub {
    my ($orig,$self) = @_;

    my $usage;
    # Get usage from command if available
    if ($self->can('command_usage')
        && $self->command_usage_predicate) {
        $usage = $self->command_usage;
    }

    # Autobuild usage
    unless ($usage) {
        my $caller      = '<tag=caller>'.$self->app_base.'</tag>';
        my @parameter   = $self->command_usage_attributes($self,'parameter');
        my $command     = $caller;
        foreach my $attribute (@parameter) {
            if ($attribute->is_required) {
                $command .= " <tag=attribute_required>&lt;".$attribute->cmd_usage_name.'&gt;</tag>';
            } else {
                $command .= ' <tag=attribute_optional>['.$attribute->cmd_usage_name.']</tag>';
            }
        }
        $usage = "$command <tag=attribute_optional>[long options...]</tag>\n";
        $usage .= "$caller <tag=attribute_optional>--help</tag>";
    }

    return $self->command_message(
        header  => 'usage:',
        body    => $usage
    ); # LOCALIZE
};

1;