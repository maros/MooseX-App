package Test03;

use MooseX::App qw(Config Color);
 
has 'global_option' => (
    is            => 'rw',
    isa           => 'Bool',
    #default       => 0,
    #required      => 1,
    documentation => q[Enable this to do fancy stuff],
);

has '_hidden_option' => (
    is            => 'rw',
    traits        => [qw(NoGetopt)],
);

1;