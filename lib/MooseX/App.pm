package MooseX::App;
# ============================================================================

our $AUTHORITY = 'cpan:MAROS';
our $VERSION = '1.00';

use Moose::Exporter;

my ($IMPORT,$UNIMPORT,$INIT_META) = Moose::Exporter->build_import_methods(
    with_meta           => [ 'app_namespace','app_base' ],
    also                => 'Moose',
    install             => [qw(unimport init_meta)],
);

sub import {
    my ( $class, @plugins ) = @_;
    
    # Get caller
    my ($caller_class) = caller();
    
    # Call Moose-Exporter generated importer
    $class->$IMPORT( { into => $caller_class } );
    
    # Loop all requested plugins
    foreach my $plugin (@plugins) {
        
        my $plugin_class = 'MooseX::App::Plugin::'.$plugin;
        # TODO eval plugin class
        Class::MOP::load_class($plugin_class);
        
        $plugin_class->init_meta(
            for_class   => $caller_class,
        )
    }
}

sub init_meta {
    shift;
    my (%args) = @_;
    
    my $meta = Moose->init_meta( %args );
    
    # Add meta role
    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => {
            class               => ['MooseX::App::Meta::Role::Class::Base'],
            attribute           => ['MooseX::App::Meta::Role::Attribute'],
        },
    );
    
    # Add class role
    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $args{for_class},
        roles => ['MooseX::App::Base'],
    );
    
    return $meta;
}

sub app_namespace($) {
    my ( $meta, $name ) = @_;
    return $meta->app_namespace($name);
}

sub app_base($) {
    my ( $meta, $name ) = @_;
    return $meta->app_base($name);
}

no Moose;
1;

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

MooseX::App is Copyright (c) 2012 Maroš Kollár.

This library is free software and may be distributed under the same terms as 
perl itself. The full text of the licence can be found in the LICENCE file 
included with this module.


1;