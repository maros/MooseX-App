# ============================================================================
package MooseX::App::Plugin::BashCompletion;
# ============================================================================

use 5.010;
use utf8;

use Moose::Exporter;

sub init_meta {
    my ($self,%args) = @_;
    
    # Add meta role
    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => {
            class               => ['MooseX::App::Plugin::BashCompletion::Meta::Class'],
            #attribute           => ['MooseX::App::Meta::Role::Attribute'],
        },
    );
    
#    my $metaclass = Moose::Meta::Class->create_anon_class(
#        superclasses => [$args{for_class}],
#    );
    
    # Add class role
    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $args{for_class},
        roles => ['MooseX::App::Plugin::BashCompletion::Role'],
    );
    
}
1;