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

__END__

=pod

=head1 NAME

MooseX::App::Role - Use documentation attributes in a role

=head1 DESCRIPTION

 package MyApp::Role::SomeRole;
 
 use Moose::Role; # optional
 use MooseX::App::Role;
 
 has 'testattr' => (
    isa             => 'rw',
    command_tags    => [qw(Important! Nice))],
 );

=cut