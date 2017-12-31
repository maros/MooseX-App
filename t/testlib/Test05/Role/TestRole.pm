# ============================================================================
package Test05::Role::TestRole;
# ============================================================================
use utf8;

use namespace::autoclean;
use MooseX::App::Role;

option 'roleattr' => (
    is              => 'rw',
    isa             => 'Str',
    cmd_tags        => ['Role'],
);

parameter 'param_c' => (
    is            => 'rw',
    isa           => 'Str',
);

1;