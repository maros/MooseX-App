# -*- perl -*-

# t/09_classes.t - Test classes

use Test::Most tests => 3+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test04;
use Test03;

subtest 'Extend base class' => sub {
    local @ARGV = qw();
    my $test01 = Test04->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    like($test01->blocks->[2]->body,qr/--test1\s+\[Integer\]/,'--test1 included');
    like($test01->blocks->[2]->body,qr/--test2\s+\[Flag\]/,'--test2 included');
    unlike($test01->blocks->[2]->body,qr/--test3/,'--test3 not included');
};

subtest 'Wrong usage' => sub {
    throws_ok { Test03->new->new_with_command } qr/new_with_command is a class method/, 'Only callable as class method';
    use Test03::SomeCommand;
    throws_ok { Test03::SomeCommand->new_with_command } qr/new_with_command may only be called from the application base package/, 'new_with_command may only be called from the application base package';
    throws_ok { Test03->new_with_command(1,2,3) } qr/new_with_command got inavlid extra arguments/, 'Wrong default args';

};

subtest 'Conflicts' => sub {
    local @ARGV = qw(broken --conflict a);
    throws_ok { 
        Test03->new_with_command;
    } qr/Command line option conflict/, 'Conflict detected';
};