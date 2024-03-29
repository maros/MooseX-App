# ============================================================================
package MooseX::App::Message::BlockColor;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Block);

use Term::ANSIColor qw();
use IO::Interactive qw(is_interactive);

BEGIN {
    if ($^O eq 'MSWin32') {
        Class::Load::try_load_class('Win32::Console::ANSI');
    }
};

sub stringify {
    my ($self) = @_;

    my $header_color;
    my $body_color;
    my $type = $self->type;
    if($type eq 'error') {
        $header_color = 'bright_red bold';
        $body_color = 'bright_red';
    }
    elsif($type eq 'default') {
        $header_color = 'bold';
    }
    else {
        $header_color = $type;
    }

    my $message = '';
    if ($self->has_header) {
        $message .= $self->_wrap_color($header_color,$self->header)."\n";
    }

    if ($self->has_body) {
        $message .= $self->_wrap_color($body_color,$self->body)."\n\n";
    }

    return $message;
}

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
