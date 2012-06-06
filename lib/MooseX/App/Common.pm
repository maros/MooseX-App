# ============================================================================
package MooseX::App::Common;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose::Role;
with 'MooseX::Getopt' => { 
    -excludes => [ 'help_flag', '_compute_getopt_attrs','new_with_command' ] 
};

has 'help_flag' => (
    is              => 'ro', isa => 'Bool',
    traits          => ['AppOption','Getopt'],
    cmd_flag        => 'help',
    cmd_aliases     => [ qw(usage ?) ],
    documentation   => 'Prints this usage information.',
);

# Dirty hack to hide private attributes from MooseX-Getopt
sub _compute_getopt_attrs {
    my ($class) = @_;

    my @attrrs = sort { $a->insertion_order <=> $b->insertion_order }
        grep { $_->does('AppOption') } 
        $class->meta->get_all_attributes;

    return @attrrs;
}


1;