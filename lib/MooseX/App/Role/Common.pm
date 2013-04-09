# ============================================================================
package MooseX::App::Role::Common;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

has extra_argv => (
    is => 'rw', 
    isa => 'ArrayRef', 
);

has 'help_flag' => (
    is              => 'ro', 
    isa             => 'Bool',
    traits          => ['AppOption'],
    cmd_flag        => 'help',
    cmd_aliases     => [ qw(h usage ?) ],
    cmd_type        => 'proto',
    documentation   => 'Prints this usage information.', # LOCALIZE
);

1;