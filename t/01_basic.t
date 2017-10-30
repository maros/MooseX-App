# -*- perl -*-

# t/01_basic.t - Basic tests

use Test::Most tests => 12+1;
use Test::NoWarnings;

use FindBin qw();
use lib 't/testlib';

use Test01;

subtest 'Excact command with option' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --global 10)]);
    my $test01 = Test01->new_with_command();
    isa_ok($test01,'Test01::CommandA');
    is($test01->global,10,'Param is set');
};

subtest 'Fuzzy command with option' => sub {
    my $test02 = Test01->new_with_command( ARGV => [qw(Command_A --globa 11)]);
    isa_ok($test02,'Test01::CommandA');
    is($test02->global,11,'Param is set');
};

subtest 'Wrong command' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(xxxx --global 10)]);
    my $test03 = Test01->new_with_command;
    isa_ok($test03,'MooseX::App::Message::Envelope');

    like($test03->blocks->[0]->block,qr/<headline=error>Unknown command 'xxxx'/,'Message is set');
    like($test03->blocks->[1]->block,qr/usage:/,'Usage set');
    like($test03->blocks->[1]->block,qr|<tag=caller>01_basic.t</tag> <tag=command>&lt;command&gt;</tag> <tag=attribute_optional>\[long options\.\.\.\]</tag>|,'Usage body set');
    like($test03->blocks->[3]->block,qr|global options:|,'Global options set');
    like($test03->blocks->[3]->block,qr|<key>--config</key>|,'Config key is set');
    like($test03->blocks->[3]->block,qr|<key>--help -h --usage -\?</key>|,'Help key is set');
    like($test03->blocks->[4]->block,qr|<description>Test class command B for test 01</description>|,'Command is set');
};

subtest 'Help for command' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --help)]);
    my $test04 = Test01->new_with_command;
    isa_ok($test04,'MooseX::App::Message::Envelope');
    my $rendered = $test04->stringify;
    is($rendered,'usage:
    01_basic.t command_a [long options...]
    01_basic.t help
    01_basic.t command_a --help

description:
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras dui velit,
    varius nec iaculis vitae, elementum eget mi.
    * bullet1
    * bullet2
    * bullet3
    Cras eget mi nisi. In hac habitasse platea dictumst.

options:
    --global              test [Required; Integer; Important!]
    --command_local1      some docs about the long texts that seem to occur
                          randomly [Integer; Env: LOCAL1; Important]
    --command_local2      Verylongwordwithoutwhitespacestotestiftextformating
                          worksproperlyandreallybrakes [Env: LOCAL2]
    --config              Path to command config file
    --help -h --usage -?  Prints this usage information [Flag]
','Rendered message ok');
};

subtest 'With extra args' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(Command_b --global 10 --param_b aaa)]);
    my $test02 = Test01->new_with_command( 'param_b' => 'bbb', 'global' => 20, 'private'=>5  );
    isa_ok($test02,'Test01::CommandB');
    is($test02->global,20,'Param global is set');
    is($test02->param_b,'bbb','Param param_b is set');
    is($test02->private,5,'Param private is set');
};

subtest 'Wrapper script' => sub {
    my $output = `$^X $FindBin::Bin/example/test01.pl command_a --command_local2 test --global 10`;
    is($output,'RUN COMMAND-A:test','Output is ok');
};

subtest 'Custom help text' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_b --help)]);
    my $test06 = Test01->new_with_command;
    isa_ok($test06,'MooseX::App::Message::Envelope');
    like($test06->blocks->[0]->block,qr|usage:|,'Usage is set');
    like($test06->blocks->[0]->block,qr|use with care|,'Usage is ok');
    like($test06->blocks->[1]->block,qr|description:|,'description is set');
    like($test06->blocks->[1]->block,qr|Some description of <tag=bold>command B</tag>|,'Description is ok');
};

subtest 'Input errors missing' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --command_local1)]);
    my $test07 = Test01->new_with_command;
    isa_ok($test07,'MooseX::App::Message::Envelope');
    like($test07->blocks->[0]->block,qr|Missing value for 'command_local1'|,'Error message ok');
};

subtest 'Input errors type' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a --command_local1 sss)]);
    my $test08 = Test01->new_with_command;
    isa_ok($test08,'MooseX::App::Message::Envelope');
    like($test08->blocks->[0]->block,qr|Invalid value for 'command_local1'|,'Error message ok');
    like($test08->blocks->[0]->block,qr|Value must be an integer \(not 'sss'\)|,'Error message ok');
};

subtest 'Global help requested' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(help)]);
    my $test09 = Test01->new_with_command;
    isa_ok($test09,'MooseX::App::Message::Envelope');
    like($test09->renderer->render($test09->blocks->[0]),qr/    01_basic\.t <command> \[long options\.\.\.\]/,'Help message ok');
};

subtest 'Missing command' => sub {
    MooseX::App::ParsedArgv->new(argv => []);
    my $test10 = Test01->new_with_command;
    isa_ok($test10,'MooseX::App::Message::Envelope');
    like($test10->renderer->render($test10->blocks->[0]),qr|Missing command|,'Error message ok');
};

subtest 'Extra params' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(command_a something else)]);
    my $test11 = Test01->new_with_command;
    isa_ok($test11,'MooseX::App::Message::Envelope');
    like($test11->renderer->render($test11->blocks->[0]),qr|Unknown parameter 'else'|,'Error message ok');
};

