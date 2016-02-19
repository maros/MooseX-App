# ============================================================================
package MooseX::App::Message::Renderer::Color;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Renderer::Basic);

use Term::ANSIColor qw();
use IO::Interactive qw(is_interactive);

BEGIN {
    if ($^O eq 'MSWin32') {
        Class::Load::try_load_class('Win32::Console::ANSI');
    }
};

__PACKAGE__->meta->make_immutable;
1;