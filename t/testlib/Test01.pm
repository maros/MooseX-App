package Test01;

use Moose;
use MooseX::App;
with qw(MooseX::App::Role::Config);

has 'global' => (
    isa             => 'Int',
    is              => 'rw',
    required        => 1,
    documentation   => q[test],
    command_tags    => ['Important!'],
);

1;