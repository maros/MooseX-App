package Test02::Command::Record;

use Moose;
use MooseX::App::Command;
extends qw(Test02);

command_short_description "Very long short descritpion that is very likely to break somewhere";

1;