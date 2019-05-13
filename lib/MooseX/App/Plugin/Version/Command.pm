# ============================================================================
package MooseX::App::Plugin::Version::Command;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;
use MooseX::App::Command;
use MooseX::App::Message::Builder;

command_short_description q(Print the current version);

sub version {
    my ($self,$app) = @_;

    my @parts = (
        HEADLINE('VERSION'),
        PARAGRAPH(
            $app->meta->app_base. ' version ',
            TAG({type => 'version'}, $app->VERSION),
            NEWLINE(),
            'MooseX::App version ',
            TAG({type => 'version'}, $MooseX::App::VERSION),
            NEWLINE(),
            'Perl version ',
            TAG({type => 'version'}, sprintf("%vd", $^V)),
        )
    );

    my %pod_raw = MooseX::App::Utils::parse_pod($app->meta->name);

    foreach my $part ('COPYRIGHT','LICENSE','COPYRIGHT AND LICENSE','AUTHOR','AUTHORS') {
        if (defined $pod_raw{$part}) {
            push(@parts,
                HEADLINE($part),
                PARAGRAPH(RAW(
                    $pod_raw{$part}
                ))
            );
        }
    }

    return MooseX::App::Message::Envelope->new(@parts);
}

__PACKAGE__->meta->make_immutable;
1;