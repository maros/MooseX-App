# ============================================================================
package MooseX::App::Meta::Role::Attribute::Option;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

{
    package Moose::Meta::Attribute::Custom::Trait::AppOption;
    sub register_implementation { 'MooseX::App::Meta::Role::Attribute::Option' }
}

1;