# ============================================================================
package MooseX::App::Command;
# ============================================================================

use 5.010;
use utf8;

use Moose ();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => [ 'command_short_description', 'command_long_description' ],
    also      => 'Moose',
);

sub init_meta {
    shift;
    my (%args) = @_;
    
    my $meta = Moose->init_meta( %args );
    
    Moose::Util::MetaRole::apply_metaroles(
        for             => $meta,
        class_metaroles => {
            class           => ['MooseX::App::Meta::Role::Class::Command'],
            attribute       => ['MooseX::App::Meta::Role::Attribute'],
        },
        role_metaroles => {
            attribute       => ['MooseX::App::Meta::Role::Attribute'],
        },
    );
    
    return $meta;
}

sub command_short_description($) {
    my ( $meta, $description ) = @_;
    return $meta->command_short_description($description);
}

sub command_long_description($) {
    my ( $meta, $description ) = @_;
    return $meta->command_long_description($description);
}

no Moose;
1;

__END__

=pod

=head1 NAME

MooseX::App::Command - Use documentation attributes in a command class

=head1 DESCRIPTION

 package MyApp::SomeCommand;
 
 use Moose; # optional
 use MooseX::App::Command
 
 has 'testattr' => (
    isa             => 'rw',
    command_tags    => [qw(Important! Nice))],
 );

=cut

1;