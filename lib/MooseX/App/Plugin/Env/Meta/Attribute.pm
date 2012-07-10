# ============================================================================
package MooseX::App::Plugin::Env::Meta::Attribute;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;
use Moose::Util::TypeConstraints;
 
subtype 'MooseX::App::Types::Env',
    as 'Str',
    where { m/^[A-Z0-9_]+$/ };

has 'cmd_env' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::Env',
    predicate   => 'has_cmd_env',
);

{
    package Moose::Meta::Attribute::Custom::Trait::AppEnv;
    
    use strict;
    use warnings;
    
    sub register_implementation { return 'MooseX::App::Plugin::Env::Meta::Attribute' }
}

1;