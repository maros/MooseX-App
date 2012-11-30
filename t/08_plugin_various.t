# -*- perl -*-

# t/08_plugin_various.t - Test various plugin

use Test::Most tests => 7+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test03;

{
    explain('Test 1: Bash completion');
    local @ARGV = qw(bash_completion);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    my $bash_completion = $test01->stringify;
    like($bash_completion,qr/_t_macc_some_command\(\)\s\{/,'some_command present');
    like($bash_completion,qr/--global_option/,'global_option present');
    like($bash_completion,qr/--roleattr/,'roleattr present');
}

{
    explain('Test 2: Version');
    local @ARGV = qw(version);
    my $test02 = Test03->new_with_command;
    isa_ok($test02,'MooseX::App::Message::Envelope');
    my $version = $test02->stringify;
    like($version,qr/\s*08_plugin_various\.t\s+version\s+22\.02/s,'Check for app version');
    like($version,qr/\s*MooseX::App\sversion\s\d+\.\d+/s,'Check for MooseX::App version');
}