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
    $version .= "MooseX::App version ".$MooseX::App::VERSION."\n";
    $version .= "Perl version ".sprintf("%vd", $^V)."\n";
    
    # TODO add copyright/license
        
    return $version;
}

__PACKAGE__->meta->make_immutable;
1;