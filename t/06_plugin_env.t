# -*- perl -*-

# t/06_plugin_env.t - Test env plugin

use Test::Most tests => 4+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test01;

subtest 'Command with argv' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --command_local1 11 --global 1)]);
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandA');
    is($test01->command_local1,'11','Arg from command config');
};

subtest 'Command only with env' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a  --global 1)]);
    local $ENV{LOCAL1} = 12;
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandA');
    is($test01->command_local1,'12','Arg from command env');
};

subtest 'Command with env and argv' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --command_local1 13 --global 1)]);
    local $ENV{LOCAL1} = 12;
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'Test01::CommandA');
    is($test01->command_local1,'13','Arg from command argv');
};

subtest 'Env not passing type constraint' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --global 1)]);
    local $ENV{LOCAL1} = 'aa';
    my $test01 = Test01->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Invalid value for 'command_local1'","Message ok");
};