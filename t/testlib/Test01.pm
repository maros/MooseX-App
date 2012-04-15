package Test01;

use Moose;
use MooseX::App qw(Config);

has 'global' => (
    isa             => 'Int',
    is              => 'rw',
    required        => 1,
    documentation   => q[test],
    cmd_tags        => ['Important!'],
);

1;