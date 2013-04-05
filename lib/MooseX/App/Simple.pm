package MooseX::App::Simple;
# ============================================================================«

use 5.010;
use utf8;
use strict;
use warnings;

use Moose::Exporter;
use MooseX::App::Exporter qw(app_base app_fuzzy option parameter command_short_description command_long_description command_usage);
use MooseX::App::Meta::Role::Attribute::Option;
use MooseX::App::Message::Envelope;
use Scalar::Util qw(blessed);

our $VERSION = '1.15';

my ($IMPORT,$UNIMPORT,$INIT_META) = Moose::Exporter->build_import_methods(
    with_meta           => [ qw(app_base app_fuzzy option parameter command_short_description command_long_description command_usage) ],
    also                => [ 'Moose' ],
    as_is               => [ 'new_with_options' ],
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
    $args{roles}        = ['MooseX::App::Role::Base' ];
    $args{metaroles}    = {
        class               => [
            'MooseX::App::Meta::Role::Class::Base',
            'MooseX::App::Meta::Role::Class::Simple',
            'MooseX::App::Meta::Role::Class::Command'
        ],
        attribute           => [
            'MooseX::App::Meta::Role::Attribute::Option'
        ],
    };
    my $meta = MooseX::App::Exporter->process_init_meta(%args);
    
    $for_class->meta->app_commands({ 'self' => $for_class });
    
    return $meta;
}

sub new_with_options {
    my ($class,@args) = @_;

    Moose->throw_error('new_with_options is a class method')
        if ! defined $class || blessed($class);

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
    my $parsed_argv = MooseX::App::ParsedArgv->new();
    $parsed_argv->argv(\@ARGV);

    return $class->initialize_command_class($class,%args);
}

no Moose;
1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Simple - Single command applications

=head1 SYNOPSIS

  package MyApp;
  use MooseX::App::Simple qw(Config Color);
  
  parameter 'param' => (
      is            => 'rw',
      isa           => 'Str',
      documentation => q[First parameter],
      required      => 1,
  ); # Positional parameter
  
  option 'my_option' => (
      is            => 'rw',
      isa           => 'Bool',
      documentation => q[Enable this to do fancy stuff],
  ); # Option (--my_option)
  
  has 'private' => ( 
      is              => 'rw',
  ); # not exposed
  
  sub run {
      my ($self) = @_;
      # Do something
  }

And then in some simple wrapper script:
 
 #!/usr/bin/env perl
 use MyApp;
 MyApp->new_with_options->run;

=head1 DESCRIPTION

MooseX-App-Simple works basically just as MooseX-App, however it does 
not search for commands and assumes that you have all options defined
in the current class.

Read the L<Tutorial|MooseX::App::Tutorial> for getting started with a simple 
MooseX::App command line application.

=head1 METHODS

=head2 new_with_options

 my $myapp_command = MyApp->new_with_options();

This method reads the command line arguments from the user and tries to create
instantiate the current class with the ARGV-input. If it fails it retuns a 
L<MooseX::App::Message::Envelope> object holding an error message.

You can pass a hash or hashref of default params to new_with_options

 MyApp->new_with_options( %default );

=head1 OPTIONS

Same as in L<MooseX::App>

=head1 PLUGINS

Same as in L<MooseX::App>. However plugings adding commands (eg. version)
will not work with MooseX::App::Simple.

=head1 SEE ALSO

Read the L<Tutorial|MooseX::App::Tutorial> for getting started with a simple 
MooseX::App command line application.

See L<MooseX::Getopt> and L<MooX::Options> for alternatives

=cut
