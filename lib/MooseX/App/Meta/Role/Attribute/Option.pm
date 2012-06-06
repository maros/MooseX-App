# ============================================================================
package MooseX::App::Meta::Role::Attribute::Option;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;
with qw(MooseX::Getopt::Meta::Attribute::Trait);


has 'cmd_tags' => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    predicate   => 'has_cmd_tags',
);

{
    package Moose::Meta::Attribute::Custom::Trait::AppOption;
    sub register_implementation { return 'MooseX::App::Meta::Role::Attribute::Option' }
}

1;