# -*- perl -*-

# t/02_meta.t - MOP tests

use Test::Most tests => 22+1;
use Test::NoWarnings;
use Test::Output;

use lib 't/testlib';

use Test01;

my $meta = Test01->meta;

is($meta->app_namespace,'Test01','Command namespace ok');
is($meta->app_base,'02_meta.t','Command base ok');
is($meta->app_messageclass,'MooseX::App::Message::Block','Message class');

ok(Test01->can('new_with_command'),'Role applied to base class');
ok(Test01->can('initialize_command'),'Role applied to base class');

my %commands = $meta->commands;

is(scalar keys %commands,2,'Found two commands');
is($commands{command_a},'Test01::CommandA','Command A found');
is($meta->matching_commands('COMMAND_a'),'command_a','Command A matched');
is(join(',',$meta->matching_commands('COMMAND')),'command_a,command_b','Command A and B matched');

#cmp_deeply([ $meta->command_usage_attributes_raw ],[ 'commanda_loca1','commanda_loca2','global' ],'Command A and B matched');
#explain [ $meta->command_usage_attributes_raw ];