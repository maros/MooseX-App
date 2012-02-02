package MooseX::App::Meta::Role::Attribute;

use utf8;
use 5.010;

use Moose::Role;

has 'command_tags' => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    predicate   => 'has_command_tags',
);

1;