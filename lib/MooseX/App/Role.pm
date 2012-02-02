# ============================================================================
package MooseX::App::Role;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role ();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    also      => 'Moose::Role',
);

sub init_meta {
    shift;
    my (%args) = @_;
    
    my $meta = Moose::Role->init_meta( %args );
    
    Moose::Util::MetaRole::apply_metaroles(
        for             => $meta,
        role_metaroles  => {
            applied_attribute=> ['MooseX::App::Meta::Role::Attribute'],
        },
    );
    
    return $meta;
}

1;