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
    is              => 'ro',
    isa             => 'ArrayRef[ArrayRef]',
    traits          => ['Array'],
    default         => sub { [] },
    handles         => {
        add_raw_value   => 'push',
        has_values      => 'count',
        raw_values      => 'elements',
    }
);

has 'consumed' => (
    is              => 'rw',
    isa             => 'Bool',
    default         => sub {0},
);

has 'type' => (
    is              => 'ro',
    isa             => 'Str',
    required        => 1,
);

has 'raw' => (
    is              => 'ro',
    isa             => 'Str',
    predicate       => 'has_raw',
);

has 'occurrence' => (
    is              => 'ro',
    isa             => 'Int',
    default         => sub { 1 },
    traits          => ['Counter'],
    handles         => {
        inc_occurrence   => 'inc',
    }
);

sub original {
    my ($self) = @_;
    if ($self->has_raw) {
        return $self->raw;
    } else {
        return $self->key;
    }
}

sub add_value {
    my ($self,$value,$position) = @_;
    $position //= 999;
    $self->add_raw_value([ $value,$position ]);
}

sub all_values {
    return map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        $_[0]->raw_values;
}

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
            return join(' ',map { $key.' '.$_ } $self->all_values);
        }
    }
    return;
}

__PACKAGE__->meta->make_immutable();
1;

=pod

=head1 NAME

MooseX::App::ParsedArgv::Element - Parsed element from @ARGV

=head1 DESCRIPTION

Every instance of this class represents a logical entity from @ARGV

=head1 METHODS

=head2 key

Parameter value or option key

=head2 value

Arrayref of values. A value itself is an arrayref of the raw value and the
original position in ARGV.

=head2 raw

Raw value as supplied by the user

=head2 type

Type of element. Can be 'option', 'parameter' or 'extra'

=head2 occurrence

Number of occurrences in @ARGV

=head2 consumed

Flag that indicates if element was already consumed

=head2 consume

Consumes element. Dies if element is already consumed

=head2 serialize

Serializes element (Does not procuce output that is identical with original @ARGV)

=cut