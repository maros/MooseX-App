# ============================================================================
package MooseX::App::Plugin::Color;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;
    
    return {
        class   => ['MooseX::App::Plugin::Color::Meta::Class'],
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Color - Colorfull output for your MooseX::App appications

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(BashCompletion);

In your shell:

 bash$ myapp bash_completion > myapp-complete.sh
 bash$ source myapp-complete.sh

=head1 DESCRIPTION

TODO

=cut