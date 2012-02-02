package Test01::CommandA;

use Moose;
use MooseX::App::Command;
extends qw(Test01);

has 'commanda_loca1' => (
    isa             => 'Int',
    is              => 'rw',
    documentation   => 'some docs about the long texts that seem to occur randomly',
    command_tags    => [qw(Important)],
);

has 'commanda_loca2' => (
    isa             => 'Str',
    is              => 'rw',
    documentation   => q[xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxX]
);

command_long_description "Hase ist sooo super das geht auf keine Kuhaut mehr, das ist soo abartig. Echt das ist die Wahrheit";
command_short_description "Hase";


1;