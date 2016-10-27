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
    isa             => 'ArrayRef[MooseX::App::ParsedArgv::Value]',
    traits          => ['Array'],
    default         => sub { [] },
    handles         => {
        push_value      => 'push',
        count_values    => 'count',
        list_values     => 'elements',
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


sub original {
    my ($self) = @_;

    # TODO fixthis
    if ($self->count_values && $self->value->[-1]->has_raw) {
        return $self->value->[-1]->has_raw;
    } else {
        return $self->key;
    }
}

sub add_value {
    my ($self,$value,$position,$raw) = @_;

    $self->push_value(MooseX::App::ParsedArgv::Value->new(
        value       => $value,
        (defined $position ? (position => $position):()),
        (defined $raw ? (raw => $raw):()),
    ));
}

sub all_scalar_values {
    return map { $_->value }
        $_[0]->all_values;
}

sub all_values {
    return sort { $a->position <=> $b->position }
        $_[0]->list_values;
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
            return $self->key;
        }
        when ('parameter') {
            return $self->key;
        }
        when ('option') {
            my $key = (length $self->key == 1 ? '-':'--').$self->key;
            return join(' ',map { $key.' '.$_->value } $self->all_values);
        }
    }
    return;
}

__PACKAGE__->meta->make_immutable();
1;

=pod

=head1 NAME

MooseX::App::ParsedArgv::Element - Parsed logical element from @ARGV

=head1 DESCRIPTION

Every instance of this class represents a logical entity from @ARGV

=head1 METHODS

=head2 key

Parameter value or option key

=head2 value

Arrayref of values. A value is represented by a MooseX::App::ParsedArgv::Value
object.

=head2 type

Type of element. Can be 'option', 'parameter' or 'extra'

=head2 consumed

Flag that indicates if element was already consumed

=head2 consume

Consumes element. Dies if element is already consumed

=head2 serialize

Serializes element (Does not procuce output that is identical with original @ARGV)

=cut