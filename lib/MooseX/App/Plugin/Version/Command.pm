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
    $version .= $app->meta->app_base. ' version <tag=version>'.$app->VERSION."</tag>\n";
    $version .= "MooseX::App version <tag=version>".$MooseX::App::VERSION."</tag>\n";
    $version .= "Perl version <tag=version>".sprintf("%vd", $^V)."</tag>";

    my @parts = (MooseX::App::Message::Block->parse('<headline>VERSION</headline><paragraph>'.$version.'</paragraph>'));

    my %pod_raw = MooseX::App::Utils::parse_pod($app->meta->name);

    foreach my $part ('COPYRIGHT','LICENSE','COPYRIGHT AND LICENSE','AUTHOR','AUTHORS') {
        if (defined $pod_raw{$part}) {
            push(@parts, MooseX::App::Message::Block->parse(
                '<headline>'.
                $part.
                '</headline><paragraph><raw>'.
                MooseX::App::Utils::string_to_entity($pod_raw{$part}).
                '</raw></paragraph>'
            ));
        }
    }

    return MooseX::App::Message::Envelope->new(@parts);
}

__PACKAGE__->meta->make_immutable;
1;