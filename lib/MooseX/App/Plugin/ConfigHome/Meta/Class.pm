# ============================================================================
package MooseX::App::Plugin::ConfigHome::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use File::HomeDir qw();
use File::Spec qw();

around 'proto_config' => sub {
    my $orig = shift;
    my ($self,$command_class,$result,$errors) = @_;

    unless (defined $result->{config}) {
        my $data_dir = File::Spec->catfile(
            File::HomeDir->my_home,
            '.'.$self->app_base
        );
        foreach my $extension (Config::Any->extensions) {
            my $check_file = File::Spec->catfile(
                $data_dir,
                'config.'.$extension
            );
            if (-e $check_file) {
                $result->{config} = $check_file;
                last;
            }
        }
    }

    return $self->$orig($command_class,$result,$errors);
};
1;
