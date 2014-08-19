package Test06;

use MooseX::App qw(Config);
app_fuzzy(1);
app_command_name {
    my @parts = split( /[_\s]+|\b|(?<![A-Z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])/, shift );
    return lc(join('-',@parts));
};

option 'some_option' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Enable this to do fancy stuff],
);



1;