# ============================================================================
package MooseX::App::Message::Renderer::Basic;
# ============================================================================
use utf8;
use 5.010;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Renderer);

__PACKAGE__->meta->make_immutable;
1;