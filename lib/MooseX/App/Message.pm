# ============================================================================
package MooseX::App::Message;
# ============================================================================

use 5.010;
use utf8;

use Moose;

use overload
    '""' => "stringify";

has 'message' => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_message',
);

has 'blocks' => (
    isa         => 'rw',
    isa         => 'ArrayRef[Str]',
    traits      => ['Array'],
    handles     => {
        add_block       => 'push',
        list_blocks     => 'elements',
    },
);

sub stringify {
    my ($self) = @_;
    
    my $message = '';
    $message .= $self->message."\n"
        if $self->has_message;
    
    foreach my $block ($self->list_blocks) {
        $message .= $block."\n\n";
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