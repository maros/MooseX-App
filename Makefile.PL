# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install 0.92;

my $from = 'lib/TEMPLATE-PATH';

# Define metadata
name            'TEMPLATE-NAME';
all_from        $from;
readme_from     $from;
readme_markdown_from $from;

perl_version    '5.008';

# Specific dependencies
requires        'Moose'                         => '2.00';
requires        'MooseX::Getopt'                => 0;
requires        'Module::Pluggable'             => 0;
requires        'Path::Class'                    => 0;
requires        'MooseX::Types::Path::Class'    => 0;
requires        'Config::Any'                   => 0;
requires        'String::CamelCase'             => 0;
requires        'List::Util'                    => 0;
requires        'Pod::Elemental'                => 0;

feature 'Colorfull output',
    -default   => 1,
    'Term::ANSIColor'                           => 0;

build_requires  'Test::Most'                    => 0;
build_requires  'Test::NoWarnings'              => 0;
build_requires  'Test::Output'                  => 0;

author_requires 'Test::Pod'                     => '1.14';
author_requires 'Test::Pod::Coverage'           => '1.04';
author_requires 'Test::Perl::Critic'            => 0;
author_requires 'Module::Install::ReadmeFromPod'=> 0;

repository 'git://github.com/maros/TEMPLATE-NAME.git';

WriteAll;