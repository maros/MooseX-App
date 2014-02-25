# ============================================================================
package MooseX::App::Message::Envelope;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;

use MooseX::App::Message::Block;

use overload
    '""' => "stringify";

has 'blocks' => (
    is          => 'rw',
    isa         => 'ArrayRef[MooseX::App::Message::Block]',
    traits      => ['Array'],
    handles     => {
        add_block       => 'push',
        list_blocks     => 'elements',
    },
);

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;
    my @args = @_;
    
    my @blocks;
    foreach my $element (@args) {
        if (blessed $element
            && $element->isa('MooseX::App::Message::Block')) {
            push(@blocks,$element);
        } else {
            push(@blocks,MooseX::App::Message::Block->new(
                header  => $element,
            ));
        }
    }

    return $self->$orig({ 
        blocks  => \@blocks,
    });
};

sub stringify {
    my ($self) = @_;
    
    my $message = '';
    foreach my $block ($self->list_blocks) {
        $message .= $block->stringify;
    }
    
    return $message;
}

sub AUTOLOAD { 
    my ($self) = @_;
    print $self->stringify;
    return $MooseX::App::Null::NULL;
}

{
    package MooseX::App::Null;
    
    use strict;
    use warnings;
    
    use overload
      'bool'   => sub { 0 },
      '""'     => sub { '' },
      '0+'     => sub { 0 };
    our $NULL = bless {}, __PACKAGE__;
    sub AUTOLOAD { return $NULL }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Message::Envelope - Message presented to the user

=head1 DESCRIPTION

Whenever MooseX::App needs to pass a message to the user, it does so by 
generating a MooseX::App::Message::Envelope object. The object usually 
contains one or more blocks (L<MooseX::App::Message::Block>) and can be
easily stringified.

Usually a MooseX::App::Message::Envelope object is generated and returned
by the L<new_with_command method in MooseX::App::Base|MooseX::App::Base/new_with_command>
if there is an error or if the user requests help.

To avoid useless object type checks when working with this method, 
MooseX::App::Message::Envelope follows the Null-class pattern. So you can do 
this, no matter if new_with_command fails or not:

 MyApp->new_with_command->some_method->only_called_if_successful;

=head1 METHODS

=head2 stringify

Stringifies the messages

=head2 add_block

Adds a new message block. Param must be a L<MooseX::App::Message::Block>

=head2 list_blocks

Returns a list on message blocks.

=head2 blocks

Message block accessor.

=head2 OVERLOAD

Stringification of this object is overloaded.

=head2 AUTOLOAD

You can call any method on the message class.
