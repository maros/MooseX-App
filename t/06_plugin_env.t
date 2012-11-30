# -*- perl -*-

# t/06_plugin_env.t - Test env plugin

use Test::Most tests => 6+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test01;

{
    explain('Test 1: Command with argv');
    local @ARGV = qw(command_a --command_local1 11 --global 1);
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandA');
    is($test01->command_local1,'11','Arg from command config');
}

{
    explain('Test 2: Command only with env');
    local @ARGV = qw(command_a  --global 1);
    local $ENV{LOCAL1} = 12;
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandA');
    is($test01->command_local1,'12','Arg from command env');
}

{
    explain('Test 2: Command with env and argv');
    local @ARGV = qw(command_a --command_local1 13 --global 1);
    local $ENV{LOCAL1} = 12;
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandA');
    is($test01->command_local1,'13','Arg from command argv');
}
