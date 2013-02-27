# ============================================================================
package MooseX::App::Exporter;
# ============================================================================

use 5.010;
use utf8;
use strict;
use warnings;

use Moose::Exporter;
use MooseX::App::Utils;
use MooseX::App::ParsedArgv;

our %PLUGIN_SPEC;

sub import {
    my ( $class, @imports ) = @_;
    
    my $caller_class = caller();
    
    my $caller_stash = Package::Stash->new($caller_class);
    my $exporter_stash = Package::Stash->new(__PACKAGE__);
    
    foreach my $import (@imports) {
        my $symbol = $exporter_stash->get_symbol('&'.$import);
        Carp::confess(sprintf('Symbol %s not defined in %s',$import,__PACKAGE__))
            unless defined $symbol;
        $caller_stash->add_symbol('&'.$import, $symbol);
    }
    
    return;
}

sub option {
    my $meta = shift;
    my $name = shift;
    my @rest = @_;
 
    Moose->throw_error('Usage: option \'name\' => ( key => value, ... )')
        if @rest % 2 == 1;
 
    my %options = ( definition_context => Moose::Util::_caller_info(), @rest );
    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
    
    $options{cmd_option} = 1;
    foreach my $attr (@$attrs) {
        my %local_options = %options;
        if ($attr =~ m/^\+(.+)/) {
            my $meta_attribute = $meta->find_attribute_by_name($1);
            unless ($meta_attribute->does('MooseX::App::Meta::Role::Attribute::Option')) {
                $local_options{traits} ||= [];
                push @{$local_options{traits}},'MooseX::App::Meta::Role::Attribute::Option'
                    unless 'AppOption' ~~ $local_options{traits}
                    || 'MooseX::App::Meta::Role::Attribute::Option' ~~ $local_options{traits};
            }
        }
        $meta->add_attribute( $attr, %local_options );
    }
    
    return;
}

sub app_fuzzy($) {
    my ( $meta, $value ) = @_;
    return $meta->app_fuzzy($value);
}

sub app_base($) {
    my ( $meta, $name ) = @_;
    
    return $meta->app_base($name);
}

sub process_plugins {
    my ($self,$caller_class,@plugins) = @_;
    
    # Loop all requested plugins
    my @plugin_classes;
    foreach my $plugin (@plugins) {
        my $plugin_class = 'MooseX::App::Plugin::'.$plugin;
        
        # TODO eval plugin class
        Class::Load::load_class($plugin_class);
        
        push (@plugin_classes,$plugin_class);
    }
    
    # Store plugin spec
    $PLUGIN_SPEC{$caller_class} = \@plugin_classes;   
}

sub process_init_meta {
    my ($self,%args) = @_;
    
    my $meta            = Moose->init_meta( %args );
    my $plugins         = $PLUGIN_SPEC{$args{for_class}} || [];
    my $apply_metaroles = delete $args{metaroles} || {};
    my $apply_roles     = delete $args{roles} || [];
    
    foreach my $plugin (@$plugins) {
        push(@{$apply_roles},$plugin,{ -excludes => [ 'plugin_metaroles' ] } )
    }
    
    push(@{$apply_roles},'MooseX::App::Role::Common')
        unless $apply_roles ~~ 'MooseX::App::Role::Common';
    
    # Process all plugins in the given order
    foreach my $plugin_class (@{$plugins}) {
        if ($plugin_class->can('plugin_metaroles')) {
            my ($metaroles) = $plugin_class->plugin_metaroles($args{for_class});
            if (ref $metaroles eq 'HASH') {
                foreach my $type (keys %$metaroles) {
                    $apply_metaroles->{$type} ||= [];
                    push (@{$apply_metaroles->{$type}},@{$metaroles->{$type}});
                }
            }
        }
    }
    
    # Add meta roles
    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => $apply_metaroles
    );
    
    # Add class roles
    Moose::Util::apply_all_roles($args{for_class},@{$apply_roles});
    
    foreach my $plugin_class (@{$plugins}) {
        if ($plugin_class->can('init_plugin')) {
            $plugin_class->init_plugin($args{for_class});
        }
    }
    
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

sub command_usage($) {
    my ( $meta, $usage ) = @_;
    return $meta->command_usage($usage);
}

1;