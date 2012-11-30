# -*- perl -*-

# t/08_plugin_bashcomplete.t - Test bashcompletion plugin

use Test::Most tests => 4+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test03;

{
    explain('Test 1: Bash completion');
    local @ARGV = qw(bash_completion);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    my $bash_completion = $test01->stringify;
    like($bash_completion,qr/_bashcomplete_t_macc_some_command\(\)\s\{/,'some_command present');
    like($bash_completion,qr/--global_option/,'global_option present');
    like($bash_completion,qr/--roleattr/,'roleattr present');
}

