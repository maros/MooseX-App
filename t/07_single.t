# -*- perl -*-

# t/07_single.t- Test MooseX::App::Single

use Test::Most tests => 2+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test05;

subtest 'Single command' => sub {
    local @ARGV = qw();
    my $test05 = Test05->new_with_options;
    isa_ok($test05,'MooseX::App::Message::Envelope');
    is($test05->blocks->[0]->header,"Required option 'another_option' missing","Check for error message");
};

subtest 'Single command' => sub {
    local @ARGV = qw(--another_option 123);
    my $test05 = Test05->new_with_options({ some_option => 1 });
    isa_ok($test05,'Test05');
    is($test05->another_option,'123','Arg from command ARGV');
    is($test05->some_option,1,'Arg from new_with_options');
};

