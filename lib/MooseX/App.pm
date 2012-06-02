package MooseX::App;
# ============================================================================«

our $AUTHORITY = 'cpan:MAROS';
our $VERSION = '1.04';

use strict;
use warnings;

use Moose::Exporter;
use MooseX::App::Meta::Role::Attribute::Option;

my ($IMPORT,$UNIMPORT,$INIT_META) = Moose::Exporter->build_import_methods(
    with_meta           => [ 'app_namespace','app_base', 'option' ],
    also                => 'Moose',
    install             => [qw(unimport init_meta)],
);

my %PLUGIN_SPEC;

sub import {
    my ( $class, @plugins ) = @_;
    
    # Get caller
    my ($caller_class) = caller();
    
    # Loop all requested plugins
    my @plugin_classes;
    foreach my $plugin (@plugins) {
        my $plugin_class = 'MooseX::App::Plugin::'.$plugin;
        
        # TODO eval plugin class
        Class::MOP::load_class($plugin_class);
        
        push (@plugin_classes,$plugin_class);
    }
    
    # Store plugin spec
    $PLUGIN_SPEC{$caller_class} = \@plugin_classes;
    
    # Call Moose-Exporter generated importer
    $class->$IMPORT( { into => $caller_class } );
}

sub init_meta {
    shift;
    my (%args) = @_;
    
    my $meta            = Moose->init_meta( %args );
    my $plugins         = $PLUGIN_SPEC{$args{for_class}} || [];
    my %apply_metaroles = (
        class               => ['MooseX::App::Meta::Role::Class::Base'],
        attribute           => ['MooseX::App::Meta::Role::Attribute::Base'],
    );
    my @apply_roles     = ('MooseX::App::Base','MooseX::App::Common');
    
    foreach my $plugin (@$plugins) {
        push(@apply_roles,$plugin,{ -excludes => [ 'plugin_metaroles' ] } )
    }
    
    # Process all plugins in the given order
    foreach my $plugin_class (@{$plugins}) {
        if ($plugin_class->can('plugin_metaroles')) {
            my ($metaroles) = $plugin_class->plugin_metaroles($args{for_class});
            if (ref $metaroles eq 'HASH') {
                foreach my $type (keys %$metaroles) {
                    $apply_metaroles{$type} ||= [];
                    push (@{$apply_metaroles{$type}},@{$metaroles->{$type}});
                }
            }
        }
    }
    
    # Add meta roles
    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => \%apply_metaroles
    );
    
    # Add class roles
    Moose::Util::MetaRole::apply_base_class_roles(
        for             => $args{for_class},
        roles           => \@apply_roles,
    );
    
    foreach my $plugin_class (@{$plugins}) {
        if ($plugin_class->can('init_plugin')) {
            $plugin_class->init_plugin($args{for_class});
        }
    }
    
    return $meta;
}

sub option {
    my $meta = shift;
    my $name = shift;
 
    Moose->throw_error('Usage: option \'name\' => ( key => value, ... )')
        if @_ % 2 == 1;
 
    my %options = ( definition_context => Moose::Util::_caller_info(), @_ );
    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
    $options{traits} ||= [];
    
    push (@{$options{traits}},'MooseX::App::Meta::Role::Attribute::Option')
        unless grep { 
            $_ eq 'MooseX::App::Meta::Role::Attribute::Option' 
            || $_ eq 'AppOption' 
        } @{$options{traits}};
    
    $meta->add_attribute( $_, %options ) for @$attrs;
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

__END__

=encoding utf8

=head1 NAME

MooseX::App - Write user-friendly command line apps with even less suffering

=head1 SYNOPSIS

In your base class:

  package MyApp;
  use MooseX::App qw(Config Color);
 
  option 'global_option' => (
      is            => 'rw',
      isa           => 'Bool',
      documentation => q[Enable this to do fancy stuff],
  );
  
  has 'private' => ( 
      is              => 'rw',
  ); # not exposed

Write multiple command classes:

  package MyApp::SomeCommand;
  use MooseX::App::Command; # important
  extends qw(MyApp); # purely optional
  
  option 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
      documentation => q[Very important option!],
  );
  
  sub run {
      my ($self) = @_;
      # Do something
  }

And then in some simple wrapper script:
 
 #!/usr/bin/env perl
 use MyApp;
 MyApp->new_with_command->run;

=head1 DESCRIPTION

MooseX-App is a highly customizeable helper to write user-friendly 
command-line applications without having to worry about most of the annoying 
things usually involved. Just take any existing Moose class, add a single 
line (C<use MooseX-App qw(PluginA PluginB ...)>) and create one class
for each command in an underlying namespace.

MooseX-App will then take care of

=over

=item * Finding, loading and initializing the command classes

=item * Creating automated doucumentation from pod and attributes

=item * Reading and validating the command line options entered by the user

=back

Commandline options are defined using the 'option' keyword which accepts
the same attributes as Moose' 'has' keyword.

  option 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
  );

This is equivalent to

  has 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
      traits        => ['AppOption'],
  );

Read the L<Tutorial|MooseX::App::Tutorial> for getting started with a simple 
MooseX::App command line application.

=head1 METHODS

=head2 new_with_command 

 my $myapp_command = MyApp->new_with_command();

This method reads the command line arguments from the user and tries to create
a command object. If it fails it retuns a L<MooseX::App::Message::Envelope> 
object holding an error message.

You can pass a hash of default params to new_with_command

 MyApp->new_with_command( %default );

=head2 initialize_command

 my $myapp_command = MyApp->new_with_command($command_name,%default);

Helper method to initialize the command class for the given command.

=head1 OPTIONS

=head2 app_base

 app_base 'my_script';

Usually MooseX::App will take the name of the calling wrapper script to 
construct the programm name in various help messages. This name can 
be changed via the app_base function.

=head2 app_namespace

 app_namespace 'MyApp::Commands';

Usually MooseX::App will take the package name of the base class as the 
namespace for commands. This namespace can be changed.

=head1 PLUGINS

The behaviour of MooseX-App can be customized with plugins. To load a
plugin just pass a list of plugin names after the C<use MooseX-App> statement.

 use MooseX::App qw(PluginA PluginB);

Read the L<Writing MooseX-App Plugins|MooseX::App::WritingPlugins> 
documentation on how to create your own plugins.

=head1 SEE ALSO

Read the L<Tutorial|MooseX::App::Tutorial> for getting started with a simple 
MooseX::App command line application.

L<MooseX::App::Cmd>, L<MooseX::Getopt> and L<App::Cmd>

=head1 SUPPORT

Please report any bugs or feature requests to 
C<bug-moosex-app@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=MooseX-App>.  
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

=cut