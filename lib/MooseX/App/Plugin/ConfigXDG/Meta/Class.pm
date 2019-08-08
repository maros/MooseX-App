package MooseX::App::Plugin::ConfigXDG::Meta::Class;

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use File::HomeDir ();
use File::Spec ();

around proto_config => sub {
    my $orig = shift;
    my ($self,$command_class,$result,$errors) = @_;

    unless (defined $result->{config}) {
        my $xdg_config_home = $ENV{XDG_CONFIG_HOME}
            || File::Spec->catdir( File::HomeDir->my_home, '.config' );

        my $config_dir = File::Spec->catdir($xdg_config_home, $self->app_base);

        foreach my $extension (Config::Any->extensions) {
            my $check_file = File::Spec->catfile($config_dir, 'config.'.$extension);
            if (-e $check_file) {
                $result->{config} = $check_file;
                last;
            }
        }
    }

    return $self->$orig($command_class,$result,$errors);
};

1;
