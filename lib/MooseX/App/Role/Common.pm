# ============================================================================
package MooseX::App::Role::Common;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

has 'help_flag' => (
    is              => 'ro', isa => 'Bool',
    traits          => ['AppOption'],
    cmd_flag        => 'help',
    cmd_aliases     => [ qw(usage ?) ],
    cmd_proto       => 1,
    documentation   => 'Prints this usage information.',
);

## Dirty hack to hide private attributes from MooseX-Getopt
#sub _compute_getopt_attrs {
#    my ($class) = @_;
#
#    my @attrrs = sort { $a->insertion_order <=> $b->insertion_order }
#        grep { $_->does('AppOption') } 
#        $class->meta->get_all_attributes;
#
#    return @attrrs;
#}

1;