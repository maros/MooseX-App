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

=encoding utf8

=head1 NAME

TEMPLATE - Description

=head1 SYNOPSIS

  use TEMPLATE;

=head1 DESCRIPTION

=head1 METHODS

=head2 Constructors

=head2 Accessors 

=head2 Methods

=head1 EXAMPLE

=head1 CAVEATS 

=head1 SEE ALSO

=head1 SUPPORT

Please report any bugs or feature requests to 
C<bug-TEMPLATE@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=TEMPLATE>.  
I will be notified, and then you'll automatically be notified of progress on 
your report as I make changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 COPYRIGHT

TEMPLATE is Copyright (c) 2010 Maroš Kollár.

This library is free software and may be distributed under the same terms as 
perl itself.

The full text of the license can be found in the LICENSE file included with 
this module.

=cut

1;