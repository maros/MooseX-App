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

1;