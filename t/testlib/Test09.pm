package Test09;

#use Moose;
use MooseX::App;
extends qw(Test09Base);

option 'test1' => (
    is              => 'rw',
    isa             => 'Int',
);

option '+test2' => ();

1;