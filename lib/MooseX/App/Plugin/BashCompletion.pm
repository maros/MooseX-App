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
    
    return $return;
};

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::BashCompletion - Bash completion for your MooseX::App appications

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(BashCompletion);

In your shell

 bash$ myapp bash_completion > myapp-complete.sh
 bash$ source myapp-complete.sh

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<MooseX::App::Cmd::Command::BashComplete>

=cut