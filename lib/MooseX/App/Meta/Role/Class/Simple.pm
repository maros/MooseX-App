# ============================================================================
package MooseX::App::Meta::Role::Class::Simple;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

around 'command_usage_header' => sub {
    my ($orig,$self) = @_;
    
    my $caller = $self->app_base;
    
    return $self->command_message(
        header  => 'usage:',
        body    => MooseX::App::Utils::format_text("$caller [long options...]
$caller --help")); # LOCALIZE
};

1;