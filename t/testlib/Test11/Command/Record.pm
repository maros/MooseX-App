package Test11::Command::Record;

use Moose;
use MooseX::App::Command;
extends qw(Test11);

command_short_description "Very long short descritpion that is very likely to break somewhere";

1;