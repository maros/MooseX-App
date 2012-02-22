# ============================================================================
package MooseX::App::Message::Envelope;
# ============================================================================

use 5.010;
use utf8;

use Moose;

use MooseX::App::Message::Block;

use overload
    '""' => "stringify";

has 'blocks' => (
    isa         => 'rw',
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
    use overload
      'bool'   => sub { 0 },
      '""'     => sub { '' },
      '0+'     => sub { 0 };
    our $NULL = bless {}, __PACKAGE__;
    sub AUTOLOAD { return $NULL }
}

1;