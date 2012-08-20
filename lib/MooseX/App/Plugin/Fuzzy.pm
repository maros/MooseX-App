# ============================================================================
package MooseX::App::Plugin::Fuzzy;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;
    
    return {
        class   => ['MooseX::App::Plugin::Fuzzy::Meta::Class'],
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Similar - Handle typos in command names

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Similar);

In your shell

 bash$ myapp pusl
 Ambiguous command 'pusl'
 Which command did you mean?
 * push
 * pull

=head1 DESCRIPTION

This plugin tries to handle typos in command names

=cut