# -*- perl -*-

# t/09_classes.t - Test classes

use Test::Most tests => 6+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test09;
use Test05;

subtest 'Extend base class' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw()]);
    my $test01 = Test09->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    like($test01->blocks->[2]->block,qr|--test1</key><description>\[<tag=attr>Integer</tag>\]|,'--test1 included');
    like($test01->blocks->[2]->block,qr|--test2</key><description>\[<tag=attr>Flag</tag>\]|,'--test2 included');
    unlike($test01->blocks->[2]->block,qr|--test3|,'--test3 not included');
};

subtest 'Wrong usage' => sub {
    throws_ok { Test05->new->new_with_command } qr/new_with_command is a class method/, 'Only callable as class method';
    use Test05::SomeCommand;
    throws_ok { Test05::SomeCommand->new_with_command } qr/new_with_command may only be called from the application base package/, 'new_with_command may only be called from the application base package';
    throws_ok { Test05->new_with_command(1,2,3) } qr/new_with_command got invalid extra arguments/, 'Wrong default args';

};

subtest 'Conflicts' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(broken --conflict a)]);
    throws_ok {
        Test05->new_with_command;
    } qr/Command line option conflict/, 'Conflict detected';
};

subtest 'Default args available with extra inheritance' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(yetanothercommand --help)]);
    my $another = Test05->new_with_command;

    isa_ok($another,'MooseX::App::Message::Envelope');
    like($another->blocks->[0]->block,qr/test05<\/tag> <tag=command>yetanothercommand/,'Help ok');
    like($another->blocks->[0]->block,qr/<headline>usage:<\/headline>/,'Help ok');

    MooseX::App::ParsedArgv->new(argv => [qw(yetanothercommand -ab --bool3)]);
    my $yetanother = Test05->new_with_command(private => 'test');
    isa_ok($yetanother,'Test05::YetAnotherCommand');
    is($yetanother->private,'test','Option has been passed on');
};

subtest 'Attributes from role' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(somecommand --roleattr a --another b)]);
    my $test = Test05->new_with_command();
    isa_ok($test,'Test05::SomeCommand');
    is($test->roleattr,'a','Attribute from role ok');
};

subtest 'Correct order from role ' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(somecommand a1 b2 ccc --another b)]);
    my $test = Test05->new_with_command;
    isa_ok($test,'Test05::SomeCommand');
    is($test->param_c,'a1','First from role');
    is($test->param_a,'b2','Second from role');
    is($test->param_b,'ccc','Third from role');

};
