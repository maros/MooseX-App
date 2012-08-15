package MooseX::App::Simple;
# ============================================================================«

use 5.010;
use utf8;
use strict;
use warnings;

our $AUTHORITY = 'cpan:MAROS';
our $VERSION = '1.05';

use Moose::Exporter;
use MooseX::App::Exporter qw(app_base option command_short_description command_long_description);
use MooseX::App::Meta::Role::Attribute::Option;
use MooseX::App::Message::Envelope;

my ($IMPORT,$UNIMPORT,$INIT_META) = Moose::Exporter->build_import_methods(
    with_meta           => [ 'app_base', 'option', 'command_short_description', 'command_long_description' ],
    also                => 'Moose',
    install             => [ 'unimport', 'init_meta' ],
);

sub import {
    my ( $class, @plugins ) = @_;
    
    # Get caller
    my ($caller_class) = caller();
    
    # Process plugins
    MooseX::App::Exporter->process_plugins($caller_class,@plugins);
    
    # Call Moose-Exporter generated importer
    return $class->$IMPORT( { into => $caller_class } );
}

sub init_meta {
    my ($class,%args) = @_;
    
    my $for_class       = $args{for_class};
    $args{roles}        = ['MooseX::App::Role::Simple' ];
    $args{metaroles}    = {
        class               => ['MooseX::App::Meta::Role::Class::Base','MooseX::App::Meta::Role::Class::Command'],
    };
    my $meta = MooseX::App::Exporter->process_init_meta(%args);
    
    $for_class->meta->app_commands({ 'self' => $for_class });
    
    return $meta;
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

 my $myapp_command = MyApp->initialize_command($command_name,%default);

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