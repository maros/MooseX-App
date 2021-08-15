# ============================================================================
package MooseX::App::Message::Renderer;
# ============================================================================
use utf8;
use 5.010;

use namespace::autoclean;
use Moose;

has 'screen_width' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 78,
);

has 'indent' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 4,
);

sub render { ... }

__PACKAGE__->meta->make_immutable;
1;