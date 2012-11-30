# -*- perl -*-

# t/07_single.t- Test MooseX::App::Single

use Test::Most tests => 4+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test05;

{
    explain('Test 1: Single command');
    local @ARGV = qw();
    my $test05 = Test05->new_with_options;
    isa_ok($test05,'MooseX::App::Message::Envelope');
    is($test05->blocks->[0]->header,"Mandatory parameter 'another_option' missing ");
}

{
    explain('Test 2: Single command');
    local @ARGV = qw(--anoth 123);
    my $test05 = Test05->new_with_options;
    isa_ok($test05,'Test05');
    is($test05->another_option,'123','Arg from command env');
}

