# ============================================================================
package MooseX::App::Plugin::ConfigHome;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;
with qw(MooseX::App::Plugin::Config);

use File::HomeDir qw();

around 'proto_config' => sub {
    my $orig = shift;
    my ($class,$command_class,$result) = @_;
    
    unless (defined $result->{config}) {
        my $home_dir = Path::Class::Dir->new(File::HomeDir->my_home);
        my $data_dir = $home_dir->subdir('.'.$class->meta->app_base);
        foreach my $extension (Config::Any->extensions) {
            my $check_file = $data_dir->file('config.'.$extension);
            if (-e $check_file) {
                $result->{config} = $check_file;
                last;
            }
        }
    }
    
    return $class->$orig($command_class,$result);
};

1;