# ============================================================================
package MooseX::App::BashCompletion;
# ============================================================================

use 5.010;
use utf8;

use Moose::Exporter;

sub init_meta {
    shift;
    my (%args) = @_;
    
    my $meta = Moose->init_meta( %args );
    
    Moose::Util::MetaRole::apply_metaroles(
        for             => $meta,
        class_metaroles => {
            class           => ['MooseX::App::Meta::Role::Class::BashCompletion'],
        },
        role_metaroles => {
            attribute       => ['MooseX::App::Meta::Role::BashCompletion'],
        },
    );
    
    return $meta;
}

1;