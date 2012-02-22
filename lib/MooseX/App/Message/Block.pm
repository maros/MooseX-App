# ============================================================================
package MooseX::App::Message::Block;
# ============================================================================

use 5.010;
use utf8;

use Moose;

use MooseX::App::Utils;

use overload
    '""' => "stringify";

has 'header' => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_header',
);

has 'type' => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'default',
);

has 'body' => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_body',
);

sub stringify {
    my ($self) = @_;
    
    my $message = '';
    $message .= $self->header."\n"
        if $self->has_header;
    
    $message .= $self->body."\n\n"
        if $self->has_body;
    
    return $message;
}

1;