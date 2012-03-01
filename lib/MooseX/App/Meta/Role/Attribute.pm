# ============================================================================
package MooseX::App::Meta::Role::Attribute;
# ============================================================================

use utf8;
use 5.010;

use Moose::Role;

has 'command_tags' => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    predicate   => 'has_command_tags',
);

{
    package Moose::Meta::Attribute::Custom::Trait::AppBase;
    sub register_implementation { 'MooseX::App::Meta::Role::Attribute' }
}

1;