# ============================================================================
package MooseX::App::Plugin::Version::Command;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;
use MooseX::App::Command;

command_short_description q(Print the current version);

sub version {
    my ($self,$app) = @_;
    
    my $version = '';
    
    $version .= $app->meta->app_base. ' version '.$app->VERSION."\n";
    $version .= "";
    
    return $version;
}

__PACKAGE__->meta->make_immutable;
1;