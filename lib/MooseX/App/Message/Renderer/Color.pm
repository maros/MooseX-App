# ============================================================================
package MooseX::App::Message::Renderer::Color;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Renderer);

use Term::ANSIColor qw();
use IO::Interactive qw(is_interactive);

BEGIN {
    if ($^O eq 'MSWin32') {
        Class::Load::try_load_class('Win32::Console::ANSI');
    }
};

sub _wrap_color {
    my ($self,$color,$string) = @_;

    return $string
        unless is_interactive()
        && defined $color;

    return Term::ANSIColor::color($color)
        .$string
        .Term::ANSIColor::color('reset');
}

__PACKAGE__->meta->make_immutable;
1;