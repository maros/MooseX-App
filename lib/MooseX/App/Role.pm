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
        with_meta       => [ 'option' ],
        for             => $meta,
        role_metaroles  => {
            applied_attribute=> ['MooseX::App::Meta::Role::Attribute::Base'],
        },
    );
    
    return $meta;
}

sub option {
    goto &MooseX::App::option;
}

1;

__END__

=pod

=head1 NAME

MooseX::App::Role - Use documentation attributes in a role

=head1 SYNOPSIS

 package MyApp::Role::SomeRole;
 
 use Moose::Role; # optional
 use MooseX::App::Role;
 
 option 'testattr' => (
    isa             => 'rw',
    cmd_tags        => [qw(Important! Nice))],
 );

=head1 DESCRIPTION

When loading this package in a role you can use the C<cmd_tags>
attribute to document an attribute. 

Alternatively you can also just use attribute traits:

 has 'testattr' => (
    isa             => 'rw',
    traits          => ['AppBase','AppOption'],
    cmd_tags        => [qw(Important! Nice))],
 );

All attibutes available in L<MooseX::Getopt::Meta::Attribute::Trait> are also applied

=cut