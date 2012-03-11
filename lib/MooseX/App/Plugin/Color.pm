# ============================================================================
package MooseX::App::Plugin::Color;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;

sub init_plugin {
    my ($self,$class) = @_;
    
    $class->meta->app_messageclass('MooseX::App::Message::BlockColor');
}; 

1;