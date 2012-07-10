# ============================================================================
package MooseX::App::Plugin::Version;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;
    
    return {
        class   => ['MooseX::App::Plugin::Version::Meta::Class'],
    }
}

around 'initialize_command' => sub {
    my $orig = shift;
    my $self = shift;
    
    my $return = $self->$orig(@_);
    
    if (blessed $return && $return->isa('MooseX::App::Plugin::Version::Command')) {
        my $version = $return->version($self);
        print $version;
        return MooseX::App::Null->new();
    }
    
    return $return;
};

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Version - Bash completion for your MooseX::App applications

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Version);

In your shell

 bash$ myapp bash_completion > myapp-complete.sh
 bash$ source myapp-complete.sh

=head1 DESCRIPTION

This plugin generates a bash completion definition for your application.

=head1 SEE ALSO

L<MooseX::App::Cmd::Command::BashComplete>

=cut