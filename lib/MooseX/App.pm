# ============================================================================«
package MooseX::App;
# ============================================================================«

use 5.010;
use utf8;
use strict;
use warnings;

our $AUTHORITY = 'cpan:MAROS';
our $VERSION = '1.16';

use MooseX::App::Meta::Role::Attribute::Option;
use MooseX::App::Exporter qw(app_base app_fuzzy option);
use MooseX::App::Message::Envelope;
use Moose::Exporter;
use Scalar::Util qw(blessed);

my ($IMPORT,$UNIMPORT,$INIT_META) = Moose::Exporter->build_import_methods(
    with_meta           => [ 'app_namespace', 'app_base', 'app_fuzzy', 'app_command_name', 'option' ],
    also                => [ 'Moose' ],
    as_is               => [ 'new_with_command' ],
    install             => [ 'unimport','init_meta' ],
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
    
    $args{roles}        = ['MooseX::App::Role::Base'];
    $args{metaroles}    = {
        class               => ['MooseX::App::Meta::Role::Class::Base'],
        attribute           => ['MooseX::App::Meta::Role::Attribute::Option'],
    };
    
    return MooseX::App::Exporter->process_init_meta(%args);
}

sub app_command_name(&) {
    my ( $meta, $namesub ) = @_;
    return $meta->app_command_name($namesub);
}

sub app_namespace($) {
    my ( $meta, $name ) = @_;
    return $meta->app_namespace($name);
}

sub new_with_command {
    my ($class,@args) = @_;
    
    Moose->throw_error('new_with_command is a class method')
        if ! defined $class || blessed($class);
    
    my $meta = $class->meta;

    Moose->throw_error('new_with_command may only be called from the application base package')
        if $meta->meta->does_role('MooseX::App::Meta::Role::Class::Command');
        
    # Extra args
    my %args;
    if (scalar @args == 1
        && ref($args[0]) eq 'HASH' ) {
        %args = %{$args[0]}; 
    } elsif (scalar @args % 2 == 0) {
        %args = @args;
    } else {
        Moose->throw_error('new_with_command got inavlid extra arguments');
    }
    
    # Get ARGV
    my $parsed_argv = MooseX::App::ParsedArgv->new;
    $parsed_argv->argv(\@ARGV);
    my $first_argv = $parsed_argv->shift_argv;
    
    # No args
    if (! defined $first_argv
        || $first_argv =~ m/^\s*$/
        || $first_argv =~ m/^-/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_message(
                header          => "Missing command", # LOCALIZE
                type            => "error",
            ),
            $meta->command_usage_global(),
        );
    # Requested help
    } elsif (lc($first_argv) =~ m/^-{0,2}?(help|h|\?|usage)$/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_usage_global(),
        );
    # Looks like a command
    } else {
        my $return = $meta->command_find($first_argv);
        
        # Nothing found
        if (blessed $return
            && $return->isa('MooseX::App::Message::Block')) {
            return MooseX::App::Message::Envelope->new(
                $return,
                $meta->command_usage_global(),
            );
        # One command found
        } else {
            my $command_class = $meta->command_get($return);
            return $class->initialize_command_class($command_class,%args);
        }
    }
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

Write multiple command classes (If you have only a single command class
you should use L<MooseX::App::Simple> instead)

  package MyApp::SomeCommand;
  use MooseX::App::Command; # important
  extends qw(MyApp); # purely optional
  
  option 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
      required      => 1,
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

On the command line:

 bash$ myapp some_command --help
 usage:
     myapp some_command [long options...]
     myapp help
     myapp some_command --help
 
 global options:
     --global_option    Enable this to do fancy stuff [Flag]
     --some_option      Very important option! [Required]
     --help --usage -?  Prints this usage information. [Flag]
 
 available commands:
     some_command    Description of some command
     another_command Description of another command
     help            Prints this usage information

=head1 DESCRIPTION

MooseX-App is a highly customizeable helper to write user-friendly 
command line applications without having to worry about most of the annoying 
things usually involved. Just take any existing L<Moose> class, add a single 
line (C<use MooseX-App qw(PluginA PluginB ...);>) and create one class
for each command in an underlying namespace.

MooseX-App will then take care of

=over

=item * Finding, loading and initializing the command classes

=item * Creating automated help and doucumentation from pod and attributes

=item * Reading, encoding and validating the command line options entered by the user

=item * Providing helpful error messages if user input cannot be validated

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
      cmd_option    => 1,
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

 MyApp->new_with_command(%default);

=head2 initialize_command_class

 my $myapp_command = MyApp->initialize_command_class($command_name,%default);

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

=head2 app_fuzzy

 app_fuzzy(1);
 OR
 app_fuzzy(0);

Enables fuzzy matching of commands and attributes. Is turned on by default.

=head2 app_command_name

 app_command_name {
     my ($package) = shift;
     # munge package name;
     return $command_name
 };

This sub can be used to control how package names should be translated
to command names.

=head1 PLUGINS

The behaviour of MooseX-App can be customized with plugins. To load a
plugin just pass a list of plugin names after the C<use MooseX-App> statement.

 use MooseX::App qw(PluginA PluginB);

Read the L<Writing MooseX-App Plugins|MooseX::App::WritingPlugins> 
documentation on how to create your own plugins.

=head1 SEE ALSO

Read the L<Tutorial|MooseX::App::Tutorial> for getting started with a simple 
MooseX::App command line application.

For alternatives you can check out

L<MooseX::App::Cmd>, L<MooseX::Getopt>, L<MooX::Options> and L<App::Cmd>

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
    
=head1 CONTRIBUTORS

In no particular order: Andrew Jones, George Hartzell, Steve Nolte, 
Michael G, Thomas Klausner, Yanick Champoux, Edward Baudrez

=head1 COPYRIGHT

MooseX::App is Copyright (c) 2012 Maroš Kollár.

This library is free software and may be distributed under the same terms as 
perl itself. The full text of the licence can be found in the LICENCE file 
included with this module.

=cut
