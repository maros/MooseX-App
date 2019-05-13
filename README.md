# NAME

MooseX::App - Write user-friendly command line apps with even less suffering

# SYNOPSIS

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
you should use [MooseX::App::Simple](https://metacpan.org/pod/MooseX::App::Simple) instead). Packackes in the namespace may be
deeply nested.

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

# DESCRIPTION

MooseX-App is a highly customisable helper to write user-friendly
command line applications without having to worry about most of the annoying
things usually involved. Just take any existing [Moose](https://metacpan.org/pod/Moose) class, add a single
line (`use MooseX-App qw(PluginA PluginB ...);`) and create one class
for each command in an underlying namespace. Options and positional parameters
can be defined as simple [Moose](https://metacpan.org/pod/Moose) accessors using the `option` and
`parameter` keywords respectively.

MooseX-App will then

- Find, load and initialise the command classes (see
[MooseX::App::Simple](https://metacpan.org/pod/MooseX::App::Simple) for single class/command applications)
- Create automated help and documentation from modules POD as well as
attributes metadata and type constraints
- Read, encode and validate the command line options and positional
parameters entered by the user from @ARGV and %ENV (and possibly prompt
the user for additional parameters see [MooseX::App::Plugin::Term](https://metacpan.org/pod/MooseX::App::Plugin::Term))
- Provide helpful error messages if user input cannot be validated
(either missing or wrong attributes or Moose type constraints not satisfied)
or if the user requests help.

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

Single letter options are treated as flags and may be combined with eachother.
However such options must have a Boolean type constraint.

    option 'verbose' => (
         is            => 'rw',
         isa           => 'Bool',
         cmd_flag      => 'v',
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

All keywords are imported by [Moosex::App](https://metacpan.org/pod/Moosex::App) (in the app base class) and
[MooseX::App::Command](https://metacpan.org/pod/MooseX::App::Command) (in the command class) or [MooseX::App::Simple](https://metacpan.org/pod/MooseX::App::Simple)
(single class application).

Furthermore, all options and parameters can also be supplied via %ENV

    option 'some_option' => (
        is            => 'rw',
        isa           => 'Str',
        cmd_env       => 'SOME_OPTION', # sets the env key
    );

Moose type constraints help MooseX::App to construct helpful error messages
and parse @ARGV in a meaningful way. The following type constraints are
supported:

- ArrayRef: Specify multiple values ('--opt value1 --opt value2',
also see [app\_permute](https://metacpan.org/pod/app_permute) and [cmd\_split](https://metacpan.org/pod/cmd_split))
- HashRef: Specify multiple key value pairs ('--opt key=value --opt
key2=value2', also see [app\_permute](https://metacpan.org/pod/app_permute))
- Enum: Display all possibilities
- Bool: Flags that do not require values
- Int, Num: Used for proper error messages

Read the [Tutorial](https://metacpan.org/pod/MooseX::App::Tutorial) for getting started with a simple
MooseX::App command line application.

# METHODS

## new\_with\_command

    my $myapp_command = MyApp->new_with_command();

This constructor reads the command line arguments and tries to create a
command class instance. If it fails it returns a
[MooseX::App::Message::Envelope](https://metacpan.org/pod/MooseX::App::Message::Envelope) object holding an error message.

You can pass a hash of default/fallback params to new\_with\_command

    my $obj = MyApp->new_with_command(%default);

Optionally you can pass a custom ARGV to this constructor

    my $obj = MyApp->new_with_command( ARGV => \@myARGV );

However, if you do so you must take care of propper @ARGV encoding yourself.

## initialize\_command\_class

    my $obj = MyApp->initialize_command_class($command_name,%default);

Helper method to instantiate the command class for the given command.

# GLOBAL OPTIONS

These options may be used to alter the default behaviour of MooseX-App.

## app\_base

    app_base 'my_script'; # Defaults to $0

Usually MooseX::App will take the name of the calling wrapper script to
construct the program name in various help messages. This name can
be changed via the app\_base function.

## app\_fuzzy

    app_fuzzy 1; # default
    OR
    app_fuzzy 0;

Enables fuzzy matching of commands and attributes. Is turned on by default.

## app\_strict

    app_strict 0; # default
    OR
    app_strict 1;

If strict is enabled the program will terminate with an error message if
superfluous/unknown positional parameters are supplied. If disabled all
extra parameters will be copied to the [extra\_argv](https://metacpan.org/pod/extra_argv) attribute. Unknown
options (with leading dashes) will always yield an error message.

The command\_strict config in the command classes allows one to set this option
individually for each command in the respective command class.

## app\_prefer\_commandline

    app_prefer_commandline 0; # default
    or
    app_prefer_commandline 1;

Specifies if parameters/options supplied via @ARGV,%ENV should take precedence
over arguments passed directly to new\_with\_command.

## app\_namespace

    app_namespace 'MyApp::Commands', 'YourApp::MoreCommands';
    OR
    app_namespace();

Usually MooseX::App will take the package name of the base class as the
namespace for commands. This namespace can be changed and you can add
multiple extra namespaces.

If app\_namespace is called with no arguments then autoloading of command
classes will be disabled entirely.

## app\_exclude

    app_exclude 'MyApp::Commands::Roles','MyApp::Commands::Utils';

A sub namespace included via app\_namespace (or the default behaviour) can
be excluded using app\_exclude.

## app\_command\_name

    app_command_name {
        my ($package_short,$package_full) = @_;
        # munge package name;
        return $command_name;
    };

This coderef can be used to control how autoloaded package names should be
translated to command names. If this command returns nothing the respective
command class will be skipped and not loaded.

## app\_command\_register

    app_command_register
       do      => 'MyApp::Commands::DoSomething',
       undo    => 'MyApp::Commands::UndoSomething';

This keyword can be used to register additional commands. Especially
useful in conjunction with app\_namespace and disabled autoloading.

## app\_description

    app_description qq[Description text];

Set the app description text. If not set this information will be taken from
the Pod DESCRIPTION or OVERVIEW sections. (see command\_description to set
usage per command)

## app\_usage

    app_usage qq[myapp --option ...];

Set a custom usage text. If not set this will be taken from the Pod SYNOPSIS
or USAGE section. If both sections are not available, the usage information
will be autogenerated. (see command\_usage to set usage per command)

## app\_permute

    app_permute 0; # default
    OR
    app_permute 1;

Allows one to specify multiple values with one key. So instead of writing
`--list element1 --list element2 --list element3` one might write
`--list element1 element2 element3` for ArrayRef elements. HashRef elements
may be expressed as <--hash key=value key2=value2>.

# GLOBAL ATTRIBUTES

All MooseX::App classes will have two extra attributes

## extra\_argv

Carries all parameters from @ARGV that were not consumed (only if app\_strict
is turned off, otherwise superfluous parameters will raise an exception).

## help\_flag

Help flag that is set when help was requested.

# ATTRIBUTE OPTIONS

Options and parameters accept extra attributes for customisation:

- cmd\_tags - Extra tags (as used by the help)
- cmd\_flag - Override option/parameter name
- cmd\_aliases - Additional option/parameter name aliases
- cmd\_split - Split values into ArrayRefs on this token
- cmd\_position - Specify option/parameter order in help
- cmd\_env - Read options/parameters from %ENV
- cmd\_count - Value of option equals to number of occurrences in @ARGV
- cmd\_negate - Adds an option to negate boolean flags

Refer to [MooseX::App::Meta::Role::Attribute::Option](https://metacpan.org/pod/MooseX::App::Meta::Role::Attribute::Option) for detailed
documentation.

# METADATA

MooseX::App will use your class metadata and POD to construct the commands and
helpful error- or usage-messages. These bits of information are utilised
and should be provided if possible:

- Package names
- [required](https://metacpan.org/pod/required) options for Moose attributes
- [documentation](https://metacpan.org/pod/documentation) options for Moose attributes
- Moose type constraints (Bool, ArrayRef, HashRef, Int, Num, and Enum)
- Documentation set via app\_description, app\_usage,
command\_short\_description, command\_long\_description and command\_usage
- POD (NAME, ABSTRACT, DESCRIPTION, USAGE, SYNOPSIS, OVERVIEW,
COPYRIGHT, LICENSE, COPYRIGHT AND LICENSE, AUTHOR and AUTHORS sections)
- Dzil ABSTRACT tag if no POD is available yet

# PLUGINS

The behaviour of MooseX-App can be customised with plugins. To load a
plugin just pass a list of plugin names after the `use MooseX-App` statement.
(Attention: order sometimes matters)

    use MooseX::App qw(PluginA PluginB);

Currently the following plugins are shipped with MooseX::App

- [MooseX::App::Plugin::BashCompletion](https://metacpan.org/pod/MooseX::App::Plugin::BashCompletion)

    Adds a command that generates a bash completion script for your application.
    See third party [MooseX::App::Plugin::ZshCompletion](https://metacpan.org/pod/MooseX::App::Plugin::ZshCompletion) for Z shell completion.

- [MooseX::App::Plugin::Color](https://metacpan.org/pod/MooseX::App::Plugin::Color)

    Colorful output for your MooseX::App applications.

- [MooseX::App::Plugin::Config](https://metacpan.org/pod/MooseX::App::Plugin::Config)

    Config files for MooseX::App applications.

- [MooseX::App::Plugin::ConfigHome](https://metacpan.org/pod/MooseX::App::Plugin::ConfigHome)

    Try to find config files in users home directory.

- [MooseX::App::Plugin::Term](https://metacpan.org/pod/MooseX::App::Plugin::Term)

    Prompt user for options and parameters that were not provided via options or
    params. Prompt offers basic editing capabilities and non-persistent history.

- [MooseX::App::Plugin::Typo](https://metacpan.org/pod/MooseX::App::Plugin::Typo)

    Handle typos in command names and provide suggestions.

- [MooseX::App::Plugin::Version](https://metacpan.org/pod/MooseX::App::Plugin::Version)

    Adds a command to display the version and license of your application.

- [MooseX::App::Plugin::Man](https://metacpan.org/pod/MooseX::App::Plugin::Man)

    Display full manpage of application and commands.

- [MooseX::App::Plugin::MutexGroup](https://metacpan.org/pod/MooseX::App::Plugin::MutexGroup)

    Allow for mutally exclusive options.

- [MooseX::App::Plugin::Depends](https://metacpan.org/pod/MooseX::App::Plugin::Depends)

    Adds dependent options.

Refer to [Writing MooseX-App Plugins](https://metacpan.org/pod/MooseX::App::WritingPlugins)
for documentation on how to create your own plugins.

# CAVEATS & KNOWN BUGS

Startup time may be an issue - escpecially if you load many plugins. If you do
not require the functionality of plugins and ability for fine grained
customisation (or Moose for that matter) then you should probably
use [MooX::Options](https://metacpan.org/pod/MooX::Options) or [MooX::Cmd](https://metacpan.org/pod/MooX::Cmd).

In some cases - especially when using non-standard class inheritance - you may
end up with command classes lacking the help attribute. In this case you need
to include the following line in your base class or command classes.

    with qw(MooseX::App::Role::Common);

When manually registering command classes (eg. via app\_command\_register) in
multiple base classes with different sets of plugins (why would you ever want
to do that?), then meta attributes may lack some attribute metaclasses. In
this case you need to load the missing attribute traits explicitly:

    option 'argument' => (
       depends => 'otherargument',
       trait   => ['MooseX::App::Plugin::Depends::Meta::Attribute'], # load trait
    );

# SEE ALSO

Read the [Tutorial](https://metacpan.org/pod/MooseX::App::Tutorial) for getting started with a simple
MooseX::App command line application.

For alternatives you can check out

[MooseX::App::Cmd](https://metacpan.org/pod/MooseX::App::Cmd), [MooseX::Getopt](https://metacpan.org/pod/MooseX::Getopt), [MooX::Options](https://metacpan.org/pod/MooX::Options), [MooX::Cmd](https://metacpan.org/pod/MooX::Cmd)and [App::Cmd](https://metacpan.org/pod/App::Cmd)

# SUPPORT

Please report any bugs or feature requests via
[https://github.com/maros/MooseX-App/issues/new](https://github.com/maros/MooseX-App/issues/new). I will be notified, and
then you'll automatically be notified of progress on your report as I make
changes.

# AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    http://www.k-1.com

# CONTRIBUTORS

Special thanks to all contributors.

In no particular order: Andrew Jones, George Hartzell, Steve Nolte,
Michael G, Thomas Klausner, Yanick Champoux, Edward Baudrez, David Golden,
J.R. Mash, Thilo Fester, Gregor Herrmann, Sergey Romanov, Sawyer X, Roman F.,
Hunter McMillen, Maik Hentsche, Alexander Stoddard, Marc Logghe, Tina Müller,
Lisa Hare

You are more than welcome to contribute to MooseX-App. Please have a look
at the [https://github.com/maros/MooseX-App/issues?q=is%3Aissue+is%3Aopen+label%3AWishlist](https://github.com/maros/MooseX-App/issues?q=is%3Aissue+is%3Aopen+label%3AWishlist)
list of open wishlist issues for ideas.

# COPYRIGHT

MooseX::App is Copyright (c) 2012-17 Maroš Kollár.

This library is free software and may be distributed under the same terms as
perl itself. The full text of the licence can be found in the LICENCE file
included with this module.
