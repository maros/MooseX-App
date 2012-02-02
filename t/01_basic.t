# -*- perl -*-

# t/01_basic.t - Basic tests

use Test::More tests => 30;
use Test::NoWarnings;
use Test::Output;

use lib 't/testlib';

use Test01;

is(Test01->meta->command_namespace,'Test01','Command namespace ok');
is(join(',',Test01->meta->commands),'command_a,Test01::CommandA,command_b,Test01::CommandB','Commands found');

{
    explain('Test 1: excact command with option');
    local @ARGV = qw(command_a --global 10);
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandA');
    is($test01->global,'10','Param is set');
}

{
    explain('Test 2: fuzzy command with option');
    local @ARGV = qw(Command_A --global 10);
    my $test02 = Test01->new_with_command;
    isa_ok($test02,'Test01::CommandA');
    is($test02->global,'10','Param is set');
}

{
    explain('Test 3: wrong command');
    local @ARGV = qw(xxxx --global 10);
    stdout_is(
        sub { Test01->new_with_command },
        "Unknown command 'xxxx'
usage: 
    01_basic.t command [long options...]
    01_basic.t help
    01_basic.t command --help

global options:
    --global           test [Required]
    --help --usage -?  Prints this usage information.

available commands:
    command_a  Hase
    command_b  
    help       Prints this usage information
",
        "Global help",
    );
}

{
    explain('Test 4: command help');
    local @ARGV = qw(command_a --help);
    stdout_is(
        sub { Test01->new_with_command },
        "usage: 
    01_basic.t command_a [long options...]
    01_basic.t help
    01_basic.t command_a --help

short description:
    Hase

options:
    --commanda_loca1   some docs
    --commanda_loca2   
    --global           test [Required]
    --help --usage -?  Prints this usage information.
",
        "Command help",
    );
}