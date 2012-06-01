package Test01::CommandA;

use Moose;
use MooseX::App::Command;
extends qw(Test01);

option 'command_local1' => (
    isa             => 'Int',
    is              => 'rw',
    documentation   => 'some docs about the long texts that seem to occur randomly',
    cmd_tags        => [qw(Important)],
);

option 'command_local2' => (
    isa             => 'Str',
    is              => 'rw',
    documentation   => q[Verylongwordwithoutwhitespacestotestiftextformatingworksproperly]
);

has 'anotherprivate' => (
    is              => 'rw',
    isa             => 'Str',
);

command_long_description "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras dui velit, varius nec iaculis vitae, elementum eget mi. 
* bullet1
* bullet2
* bullet3
Cras eget mi nisi. In hac habitasse platea dictumst.";

command_short_description "Command A!";

sub run { 
    print "RUN COMMAND-A";
}

1;