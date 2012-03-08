# ============================================================================
package MooseX::App::Plugin::Config;
# ============================================================================

use 5.010;
use utf8;

use Moose::Exporter;

sub init_meta {
    my ($self,%args) = @_;
    
    # Add class role
    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $args{for_class},
        roles => ['MooseX::App::Plugin::Config::Role'],
    );
    
}
1;