# ============================================================================
package MooseX::App::Plugin::BashCompletion;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;
    
    return {
        class   => ['MooseX::App::Plugin::BashCompletion::Meta::Class'],
    }
}

around 'initialize_command' => sub {
    my $orig = shift;
    my $self = shift;
    
    my $return = $self->$orig(@_);
    
    if (blessed $return && $return->isa('MooseX::App::Plugin::BashCompletion::Command')) {
        $return->bash_completion($self);
    }
};

1;