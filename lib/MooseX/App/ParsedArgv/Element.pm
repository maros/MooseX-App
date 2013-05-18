# ============================================================================
package MooseX::App::ParsedArgv::Element;
# ============================================================================

use 5.010;
use utf8;

use Moose;
no if $] >= 5.018000, warnings => qw(experimental::smartmatch);

has 'key' => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
);

has 'value' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    traits          => ['Array'],
    default         => sub { [] },
    handles => {
        add_value       => 'push',
        has_values      => 'count',
        get_value       => 'get',
    }
);

has 'consumed' => (
    is              => 'rw',
    isa             => 'Bool',
    default         => 0,
);

has 'type' => (
    is              => 'rw',
    isa             => 'Str',
    required        => 1,
);

sub consume {
    my ($self,$attribute) = @_;
    
    Moose->throw_error('Element '.$self->type.' '.$self->key.' is already consumed')
        if $self->consumed;
    $self->consumed(1);  
    
    return $self; 
}

sub serialize {
    my ($self) = @_;
    given ($self->type) {
        when ('extra') { 
            return $self->key
        }
        when ('parameter') { 
            return $self->key
        }
        when ('option') { 
            my $key = (length $self->key == 1 ? '-':'--').$self->key;
            join(' ',map { $key.' '.$_ } @{$self->value});
        }
    }   
}

__PACKAGE__->meta->make_immutable();

=pod

=head1 NAME

MooseX::App::ParsedArgv::Element - Parsed element from @ARGV

=head1 DESCRIPTION

Every instance of this class represents a logical element from @ARGV

=head1 METHODS

=head2 key

Parameter value or option key

=head2 value

Arrayref of values 

=head2 type

Type of element. Can be 'option', 'parameter' or 'extra'

=head2 consumed

Flag that indicates if element was already consumed

=head2 consume

Consumes element. Dies if element is already consumed

=head2 serialize

Serializes element (Does not procuce output that is identical with original @ARGV)