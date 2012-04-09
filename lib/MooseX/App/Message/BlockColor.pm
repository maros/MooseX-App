# ============================================================================
package MooseX::App::Message::BlockColor;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Block);

use Term::ANSIColor qw();

sub stringify {
    my ($self) = @_;
    
    my $header_color;
    my $body_color;
    given ($self->type) {
        when('error') {
            $header_color = 'bright_red bold';
            $body_color = 'bright_red';
        }
        when('default') {
            $header_color = 'bold';
        }
        default {
            $header_color = $_;
        }
    }
    
    my $message = '';
    if ($self->has_header) {
        if ($header_color) {
            $message .= Term::ANSIColor::color($header_color).
                $self->header.
                Term::ANSIColor::color('reset')."\n"
        } else {
            $message .= $self->header."\n"
        }
    }
    
    if ($self->has_body) {
        if ($body_color) {
            $message .= Term::ANSIColor::color($body_color).
                $self->body.
                Term::ANSIColor::color('reset')."\n\n"
        } else {
            $message .= $self->body."\n\n"
        }
    }
    
    return $message;
}

__PACKAGE__->meta->make_immutable;
1;