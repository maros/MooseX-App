# ============================================================================
package MooseX::App::Plugin::Color;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;

before 'new_with_command' => sub {
    my ($self) = @_;
    
    $self->meta->app_messageclass('MooseX::App::Message::BlockColor');
}; 

1;