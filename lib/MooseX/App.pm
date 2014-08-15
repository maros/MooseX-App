# ============================================================================«
package MooseX::App;
# ============================================================================«

use 5.010;
use utf8;
use strict;
use warnings;

our $AUTHORITY = 'cpan:MAROS';
our $VERSION = 1.29;

use MooseX::App::Meta::Role::Attribute::Option;
use MooseX::App::Exporter qw(app_usage app_description app_base app_fuzzy app_strict app_prefer_commandline option parameter);
use MooseX::App::Message::Envelope;
use Moose::Exporter;
use Scalar::Util qw(blessed);

my ($IMPORT,$UNIMPORT,$INIT_META) = Moose::Exporter->build_import_methods(
    with_meta           => [ qw(app_usage app_description app_namespace app_base app_fuzzy app_command_name app_strict option parameter) ],
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
        class               => [
            'MooseX::App::Meta::Role::Class::Base',
            'MooseX::App::Meta::Role::Class::Documentation'
        ],
        attribute           => ['MooseX::App::Meta::Role::Attribute::Option'],
    };
    
    return MooseX::App::Exporter->process_init_meta(%args);
}

sub app_command_name(&) {
    my ( $meta, $namesub ) = @_;
    return $meta->app_command_name($namesub);
}

sub app_namespace(@) {
    my ( $meta, @namespaces ) = @_;
    return $meta->app_namespace( \@namespaces );
}

sub new_with_command {
    my ($class,@args) = @_;
    
    Moose->throw_error('new_with_command is a class method')
        if ! defined $class || blessed($class);
    
    my $meta = $class->meta;
    my $metameta = $meta->meta;
    
    Moose->throw_error('new_with_command may only be called from the application base package:'.$class)
        if $metameta->does_role('MooseX::App::Meta::Role::Class::Command')
        || ! $metameta->does_role('MooseX::App::Meta::Role::Class::Base');
        
    # Extra args
    my %args;
    if (scalar @args == 1
        && ref($args[0]) eq 'HASH' ) {
        %args = %{$args[0]}; 
    } elsif (scalar @args % 2 == 0) {
        %args = @args;
    } else {
        Moose->throw_error('new_with_command got invalid extra arguments');
    }
    
    # Get ARGV
    my $parsed_argv = MooseX::App::ParsedArgv->instance();
    my $first_argv = $parsed_argv->first_argv;
    
    # Requested help
    if (defined $first_argv 
        && lc($first_argv) =~ m/^(help|h|\?|usage|-h|--help|-\?|--usage)$/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_usage_global(),
        );
    # No args
    } elsif (! defined $first_argv
        || $first_argv =~ m/^\s*$/
        || $first_argv =~ m/^-{1,2}\w/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_message(
                header          => "Missing command", # LOCALIZE
                type            => "error",
            ),
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
  use MooseX::App qw(Color);
 
  option 'global_option' => (
      is            => 'rw',
      isa           => 'Bool',
      documentation => q[Enable this to do fancy stuff],
  ); # Global option
  
  has 'private' => ( 
      is              => 'rw',
  ); # not exposed

Write multiple command classes (If you have only a single command class
you should use L<MooseX::App::Simple> instead)

  package MyApp::SomeCommand;
  use MooseX::App::Command; # important (also imports Moose)
  extends qw(MyApp); # optional, only if you want to use global options from base class
  
  # Positional parameter
  parameter 'some_parameter' => (
      is            => 'rw',
      isa           => 'Str',
      required      => 1,
      documentation => q[Some parameter that you need to supply],
  );
  
  option 'some_option' => (
      is            => 'rw',
      isa           => 'Int',
      required      => 1,
      documentation => q[Very important option!],
  ); # Option
  
  sub run {
      my ($self) = @_;
      # Do something
  }

And then you need a simple wrapper script (called eg. myapp):
 
 #!/usr/bin/env perl
 use MyApp;
 MyApp->new_with_command->run;

On the command line:

 bash$ myapp help
 usage:
     myapp <command> [long options...]
     myapp help
 
 global options:
     --global_option    Enable this to do fancy stuff [Flag]
     --help --usage -?  Prints this usage information. [Flag]
 
 available commands:
     some_command    Description of some command
     another_command Description of another command
     help            Prints this usage information

or

 bash$ myapp some_command --help
 usage:
     myapp some_command <SOME_PARAMETER> [long options...]
     myapp help
     myapp some_command --help
 
 parameters:
     some_parameter     Some parameter that you need to supply [Required]
 
 options:
     --global_option    Enable this to do fancy stuff [Flag]
     --some_option      Very important option! [Int,Required]
     --help --usage -?  Prints this usage information. [Flag]

=head1 DESCRIPTION

MooseX-App is a highly customisable helper to write user-friendly 
command line applications without having to worry about most of the annoying 
things usually involved. Just take any existing L<Moose> class, add a single 
line (C<use MooseX-App qw(PluginA PluginB ...);>) and create one class
for each command in an underlying namespace. Options and positional parameters
can be defined as simple L<Moose> accessors.

MooseX-App will then

=over

=item * Find, load and initialise the command classes (see L<MooseX-App-Simple>
for single command applications)

=item * Create automated help and documentation from modules POD and 
attributes metadata

=item * Read, encode and validate the command line options and positional 
parameters entered by the user from @ARGV (and possibly %ENV)

=item * Provide helpful error messages if user input cannot be validated (
either missing or wrong attributes or Moose type constraints not satisfied)

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
      traits        => ['AppOption'],   # Load extra metaclass
      cmd_type      => 'option',        # Set attribute type
  );

Positional parameters are defined with the 'parameter' keyword

  parameter 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
  );

This is equivalent to

  has 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
      traits        => ['AppOption'],
      cmd_type      => 'parameter',
  );

Read the L<Tutorial|MooseX::App::Tutorial> for getting started with a simple 
MooseX::App command line application.

=head1 METHODS

=head2 new_with_command 

 my $myapp_command = MyApp->new_with_command();

This constructor reads the command line arguments and tries to create a 
command class instance. If it fails it retuns a 
L<MooseX::App::Message::Envelope> object holding an error message.

You can pass a hash of default/fallback params to new_with_command

 my $obj = MyApp->new_with_command(%default);

=head2 initialize_command_class

 my $obj = MyApp->initialize_command_class($command_name,%default);

Helper method to instantiate the command class for the given command.

=head1 GLOBAL OPTIONS

=head2 app_base

 app_base 'my_script'; # Defaults to $0

Usually MooseX::App will take the name of the calling wrapper script to 
construct the program name in various help messages. This name can 
be changed via the app_base function.

=head2 app_namespace

 app_namespace 'MyApp::Commands', 'YourApp::MoreCommands';

Usually MooseX::App will take the package name of the base class as the 
namespace for commands. This namespace can be changed and you can add
multiple extra namespaces.

=head2 app_fuzzy

 app_fuzzy(1); # default
 OR
 app_fuzzy(0);

Enables fuzzy matching of commands and attributes. Is turned on by default.

=head2 app_strict

 app_strict(0); # default 
 OR
 app_strict(1); 

If strict is enabled the program will terminate with an error message if
superfluous/unknown positional parameters are supplied. If disabled all 
extra parameters will be copied to the L<extra_argv> attribute. 

The command_strict config in the command classes allows one to set this option
individually for each command.

=head2 app_command_name

 app_command_name {
     my ($package) = shift;
     # munge package name;
     return $command_name;
 };

This sub can be used to control how package names should be translated
to command names.

=head2 app_description

Set the description. If not set this information will be taken from the
Pod DESCRIPTION or OVERVIEW sections.

=head2 app_usage

Set custom usage. If not set this will be taken from the Pod SYNOPSIS or 
USAGE section. If those sections are not available, the usage
information will be autogenerated.

=head1 GLOBAL ATTRIBUTES

All MooseX::App classes will have two extra attributes

=head2 extra_argv

Carries all parameters from @ARGV that were not consumed (only if app_strict
is turned off, otherwise superfluous parameters will raise an exception).

=head2 help_flag

Help flag that is set when help was requested.

=head1 ATTRIBUTE OPTIONS

=over

=item * cmd_tags - Extra tags

=item * cmd_flag - Override option name

=item * cmd_aliases - Alternative option names

=item * cmd_split - Split values

=item * cmd_position - Option/Parameter order

=back

Refer to L<MooseX::App::Meta::Role::Attribute::Option> for detailed 
documentation.

=head1 METADATA

MooseX::App will use your class metadata and POD to construct the commands and
helpful error- or usage- messages. These bits of information are utilised 
and should be provided if possible:

=over

=item * Package names

=item * L<required> options for Moose attributes

=item * L<documentation> options for Moose attributes

=item * Moose type constraints (Bool, ArrayRef, HashRef, Int, Num, and Enum)

=item * POD (NAME, ABSTRACT, DESCRIPTION, USAGE, SYNOPSIS and OVERVIEW sections)

=item * Dzil ABSTRACT tag if no POD is available yet

=back

=head1 PLUGINS

The behaviour of MooseX-App can be customised with plugins. To load a
plugin just pass a list of plugin names after the C<use MooseX-App> statement.
(Attention: order sometimes matters)

 use MooseX::App qw(PluginA PluginB);

Currently the following plugins are shipped with MooseX::App

=over

=item * L<MooseX::App::Plugin::BashCompletion>

Adds a command that genereates a bash completion script for your application

=item * L<MooseX::App::Plugin::Color>

Colorful output for your MooseX::App applications

=item * L<MooseX::App::Plugin::Config>

Config files for MooseX::App applications

=item * L<MooseX::App::Plugin::ConfigHome>

Search config files in users home directory

=item * L<MooseX::App::Plugin::Env>

Read options and parameters from environment

=item * L<MooseX::App::Plugin::Term>

Prompt user for options and parameters not provided via options or params

=item * L<MooseX::App::Plugin::Typo>

Handle typos in command names

=item * L<MooseX::App::Plugin::Version>

Adds a command to display the version and license of your application

=item * L<MooseX::App::Plugin::Man>

Display full manpage

=back

Refer to L<Writing MooseX-App Plugins|MooseX::App::WritingPlugins> 
for documentation on how to create your own plugins.

=head1 CAVEATS & KNOWN BUGS

Startup time may be an issue - escpecially if you load many pluginc. If you do
not require plugins and ability for fine grained customisation then you should 
probably use L<MooX::Options> or L<MooX::Cmd>. 

In some cases - especially when using non-standard class inheritance - you may
end up with command classes lacking the help attribute. In this case you need
to include the following line in your base class

 with qw(MooseX::App::Role::Common);

=head1 SEE ALSO

Read the L<Tutorial|MooseX::App::Tutorial> for getting started with a simple 
MooseX::App command line application.

For alternatives you can check out

L<MooseX::App::Cmd>, L<MooseX::Getopt>, L<MooX::Options>, 
L<MooX::Cmd>  and L<App::Cmd>

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
Michael G, Thomas Klausner, Yanick Champoux, Edward Baudrez, David Golden,
J.R. Mash, Thilo Fester, Gregor Herrmann

=head1 COPYRIGHT

MooseX::App is Copyright (c) 2012-14 Maroš Kollár.

This library is free software and may be distributed under the same terms as 
perl itself. The full text of the licence can be found in the LICENCE file 
included with this module.

=cut
