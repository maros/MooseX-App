package Test06::CommandA;

use Moose;
use MooseX::App::Command;
extends qw(Test06);

option 'command_local2' => (
    isa             => 'Str',
    is              => 'rw',
    documentation   => q[Verylongwordwithoutwhitespacestotestiftextformatingworksproperly],
    cmd_env         => 'LOCAL2',
);

sub run {
    my ($self) = @_;
    print "NEW WITH A";
    $self->initialize_command_class('Test06::CommandB')->run;
    #$self->initialize_command_class('Test06::CommandB');   
}

1;