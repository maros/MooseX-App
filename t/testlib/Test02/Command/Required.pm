package Test02::Command::Required;

use Moose;
use MooseX::App::Command;
extends qw(Test02);

has 'local1' => (
    isa             => 'Int',
    is              => 'rw',
    required        => 1,
);

has 'local2' => (
    isa             => 'Bool',
    is              => 'rw',
    default         => 1,
);

1;