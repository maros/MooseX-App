package MooseX::App::Plugin::ConfigXDG;


use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;
with qw(MooseX::App::Plugin::Config);

sub plugin_metaroles {
    my ($self, $class) = @_;

    return {
        class => [
            'MooseX::App::Plugin::Config::Meta::Class',
            'MooseX::App::Plugin::ConfigXDG::Meta::Class'
        ]
    };
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::ConfigXDG - Config files in XDG config directories

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(ConfigXDG);

=head1 DESCRIPTION

Works just like L<MooseX::App::Plugin::Config>, but assumes that the config
file always resides in the user's XDG config directory.  By default, this is
C<< $HOME/.config/${app-base}/config.(yml|xml|ini|...) >>.

You can override the XDG config base (from C<< $HOME/.config >>) with the
environmental variable C<XDG_CONFIG_HOME>.

=cut
