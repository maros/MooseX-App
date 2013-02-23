# -*- perl -*-

# t/09_extend.t - Extend base classes

use Test::Most tests => 1+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test04;

subtest 'Extend base class' => sub {
    local @ARGV = qw();
    my $test01 = Test04->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    like($test01->blocks->[2]->body,qr/--test1\s+\[Integer\]/,'--test1 included');
    like($test01->blocks->[2]->body,qr/--test2\s+\[Flag\]/,'--test2 included');
    unlike($test01->blocks->[2]->body,qr/--test3/,'--test3 not included');
};
