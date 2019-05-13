# ============================================================================
package MooseX::App::Meta::Role::Class::Simple;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

use MooseX::App::Message::Builder;

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
        my $caller      = TAG({ type => 'caller'},$self->app_base);
        my @parameter   = $self->command_usage_attributes($self,'parameter');
        my @command     = $caller;
        foreach my $attribute (@parameter) {
            if ($attribute->is_required) {
                push @command,' ',TAG({ type => 'attribute_required' },'<'.$attribute->cmd_usage_name.'>');
            } else {
                push @command,' ',TAG({ type => 'attribute_optional' },'['.$attribute->cmd_usage_name.']');
            }
        }
        $usage = [
            @command,
            ' ',
            TAG({ type => 'attribute_optional'},'[long options...]'),
            NEWLINE(),
            $caller,
            ' ',
            TAG({ type => 'attribute_optional'},'--help'),
        ]
    }

    return $self->command_message(
        header  => 'usage:',
        body    => $usage
    ); # LOCALIZE
};

1;