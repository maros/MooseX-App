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
    
    Moose::Util::MetaRole::apply_base_class_roles(
        for             => $args{for_class},
        roles           => ['MooseX::Getopt'],
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

MooseX::App::Command - Load command class metaclasses

=head1 SYNOPSIS

 package MyApp::SomeCommand;
 
 use Moose; # optional
 use MooseX::App::Command
 
 has 'testattr' => (
    isa             => 'rw',
    command_tags    => [qw(Important! Nice))],
 );
 
 command_short_description 'This is a short description';

=head1 DESCRIPTION

By loading this class into your command classes you enable all documentation
features such as:
 
=over

=item * Parsing command documentation from POD

=item * Setting the command documentation manually via C<command_short_description> and C<command_long_description>

=item * Adding the C<command_tags> option to attributes

=back

=head1 FUNCTIONS

=head2 command_short_description

Set the short description

=head2 command_long_description

Set the long description

=cut

1;