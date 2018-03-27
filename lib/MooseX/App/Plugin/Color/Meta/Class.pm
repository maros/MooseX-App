# ============================================================================
package MooseX::App::Plugin::Color::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

around '_build_app_renderer' => sub {
    require MooseX::App::Message::Renderer::Color;
    return MooseX::App::Message::Renderer::Color->new();
};

1;
