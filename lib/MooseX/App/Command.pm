# ============================================================================
package MooseX::App::Command;
# ============================================================================

use 5.010;
use utf8;

use Moose ();
use MooseX::App::Exporter qw(option command_short_description command_long_description);
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => [ 'command_short_description', 'command_long_description', 'option'],
    also      => 'Moose',
);

sub init_meta {
    my ($class,%args) = @_;
    
    my $meta = Moose->init_meta( %args );
    
    Moose::Util::MetaRole::apply_metaroles(
        for             => $meta,
        class_metaroles => {
            class           => ['MooseX::App::Meta::Role::Class::Command'],
        },
    );
    
    Moose::Util::MetaRole::apply_base_class_roles(
        for             => $args{for_class},
        roles           => ['MooseX::App::Role::Common'],
    );
    
    return $meta;
}

1;

__END__

=pod

=head1 NAME

MooseX::App::Command - Load command class metaclasses

=head1 SYNOPSIS

 package MyApp::SomeCommand;
 
 use Moose; # optional
 use MooseX::App::Command
 
 option 'testattr' => (
    isa             => 'rw',
    cmd_tags        => [qw(Important! Nice))],
 );
 
 command_short_description 'This is a short description';
 command_long_description 'This is a much longer description yadda yadda';

=head1 DESCRIPTION

By loading this class into your command classes you enable all documentation
features such as:
 
=over

=item * Parsing command documentation from POD

=item * Setting the command documentation manually via C<command_short_description> and C<command_long_description>

=item * Adding the C<cmd_tags> option to options

=item * Adding all attributes available in L<MooseX::Getopt::Meta::Attribute::Trait> such as C<cmd_flag> nad C<cmd_aliases>.

=back

=head1 FUNCTIONS

=head2 command_short_description

Set the short description

=head2 command_long_description

Set the long description

=cut

1;