requires 'Moose', '2.00';
requires 'namespace::autoclean';
requires 'Module::Pluggable';
requires 'Path::Class';
requires 'MooseX::Types::Path::Class';
requires 'Config::Any';
requires 'List::Util', '1.44';
requires 'Pod::Elemental';

recommends 'IO::Interactive';
recommends 'Term::ReadKey';
recommends 'Term::ANSIColor';
recommends 'File::HomeDir';
recommends 'Text::WagnerFischer';
recommends 'Win32::Console::ANSI';

on test => sub {
  requires 'Test::Most';
  requires 'Test::NoWarnings';
};

on develop => sub {
  requires 'Test::Pod', '1.14';
  requires 'Test::Pod::Coverage', '1.04';
  requires 'Test::Perl::Critic';
  requires 'Module::Install::ReadmeFromPod';
};
