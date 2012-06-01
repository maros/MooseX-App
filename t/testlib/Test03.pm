package Test03;

use MooseX::App qw(Config Color);
 
option 'global_option' => (
    is            => 'rw',
    isa           => 'Bool',
    #default       => 0,
    #required      => 1,
    documentation => q[Enable this to do fancy stuff],
);

has 'hidden_option' => (
    is            => 'rw',
);

sub run {
    print "RAN";   
}

1;