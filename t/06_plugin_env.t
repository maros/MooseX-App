# -*- perl -*-

# t/04_role_config.t - Test env plugin

use Test::Most tests => 6+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test02;


{
    explain('Test 1: Command with argv');
    local @ARGV = qw(required --local1 11);
    my $test02 = Test02->new_with_command;
    isa_ok($test02,'Test02::Command::Required');
    is($test02->local1,'11','Arg from command config');
}

{
    explain('Test 2: Command only with env');
    local @ARGV = qw(required);
    local $ENV{LOCAL1} = 12;
    my $test02 = Test02->new_with_command;
    isa_ok($test02,'Test02::Command::Required');
    is($test02->local1,'12','Arg from command env');
}

{
    explain('Test 2: Command with env and argv');
    local @ARGV = qw(required --local1 13);
    local $ENV{LOCAL1} = 12;
    my $test02 = Test02->new_with_command;
    isa_ok($test02,'Test02::Command::Required');
    is($test02->local1,'13','Arg from command argv');
}
