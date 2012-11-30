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

around 'initialize_command_class' => sub {
    my $orig = shift;
    my $self = shift;
    
    my $return = $self->$orig(@_);
    if (blessed $return 
        && $return->isa('MooseX::App::Plugin::Version::Command')) {
        return $return->version($self);
    }
    
    return $return;
};

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Version - Adds a command to display version

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Version);

In your shell

 bash$ myapp version
 MyApp version 2.1
 MooseX::App version 1.08
 Perl version 5.16.2
 
=head1 DESCRIPTION

This plugin adds a command to display the version of your application,
MooseX::App and perl.

=cut
