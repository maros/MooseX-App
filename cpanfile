requires 'Moose', '2.00';
requires 'namespace::autoclean';
requires 'Module::Pluggable';
requires 'File::Basename';
requires 'File::Spec';
requires 'List::Util', '1.44';
requires 'Pod::Elemental';

feature 'config', 'Config plugins' => sub {
    requires 'Config::Any'; # or recommends
    requires 'File::HomeDir';
};

feature 'colour', 'Colourful output' => sub {
    requires 'IO::Interactive';
    requires 'Term::ANSIColor';
    requires 'Win32::Console::ANSI';
};

feature 'term', 'Term plugin' => sub {
    requires 'IO::Interactive';
    requires 'Term::ANSIColor';
};

feature 'typo', 'Typo plugin' => sub {
    requires 'Text::WagnerFischer';
};

on test => sub {
    requires 'Test::Most';
    requires 'Test::NoWarnings';
};

on develop => sub {
    requires 'Test::Pod', '1.14';
    requires 'Test::Pod::Coverage', '1.04';
    requires 'Test::Perl::Critic';
};
