# -*- perl -*-

# t/02_error.t

use Test::More tests => 30;
#use Test::NoWarnings;
use Test::Output;

use lib 't/testlib';

use Test02;

is(Test02->meta->command_namespace,'Test02::Command','Command namespace ok');
is(join(',',Test02->meta->commands),'required,Test02::Command::Required,error,Test02::Command::Error','Commands found');

{
    explain('Test 1: broken command');
    local @ARGV = qw(required);
    stdout_is(
        sub { Test02->new_with_command },
        "Required option missing: local1
usage: 
    02_error.t required [long options...]
    02_error.t help
    02_error.t required --help

options:
    --help --usage -?  Prints this usage information.
    --local1           [Required]
",
        "Command error and help",
    );
}

{
    explain('Test 2: required attr command');
    local @ARGV = qw(required --global a);
    stdout_is(
        sub { Test02->new_with_command },
        "Unknown option: global
usage: 
    02_error.t required [long options...]
    02_error.t help
    02_error.t required --help

options:
    --help --usage -?  Prints this usage information.
    --local1           [Required]
",
        "Command error and help",
    );
}
