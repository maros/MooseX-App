# ============================================================================
package MooseX::App::Message::Block;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;

use MooseX::App::Utils;

has 'parsed' => (
    is          => 'ro',
    isa         => 'MooseX::App::Types::MessageString',
    lazy_build  => 1,
    builder     => '_parse_block',
);

has 'block' => (
    is          => 'ro',
    isa         => 'MooseX::App::Types::MessageString',
    coerce      => 1,
    required    => 1,
);

sub raw {
    my ($class,$string) = @_;

    $string = '<raw>'.MooseX::App::Utils::string_to_entity($string).'</raw>';
    return $class->new(block => $string);
}

sub parse {
    my ($class,$string) = @_;
    return $class->new(block => $string);
}

sub _parse_block {
    my ($self) = @_;

    my $parsed = [];

    return $parsed;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Message::Block - Message block

=head1 DESCRIPTION

A simple message block with a header and body

=head1 METHODS

=head2 header

Read/set a header string

=head2 has_header

Check if a header is set

=head2 body

Read/set a body string

=head2 has_body

Check if a body is set

=head2 type

Read/set an arbitrary block type. Defaults to 'default'

=head2 stringify

Stringify a message block