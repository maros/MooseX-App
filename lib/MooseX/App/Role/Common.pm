# ============================================================================
package MooseX::App::Role::Common;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

has 'help_flag' => (
    is              => 'ro', 
    isa             => 'Bool',
    traits          => ['AppOption'],
    cmd_flag        => 'help',
    cmd_aliases     => [ qw(usage ?) ],
    cmd_proto       => 1,
    cmd_option      => 1,
    documentation   => 'Prints this usage information.',
);

1;