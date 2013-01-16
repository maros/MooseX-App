package Test02::Command::Error;

use Moose;
use MooseX::App::Command;
extends qw(Test02);

sub BUILD {
    die('XXX');
}

sub run {
    die('YYY');
}

command_usage "Use me not";
command_long_description "A very long description about a command that will always fail";
command_short_description "Short description";

1;