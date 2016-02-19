# ============================================================================
package MooseX::App::Message::Renderer::Basic;
# ============================================================================
use utf8;
use 5.010;

use namespace::autoclean;
use Moose;

no if $] >= 5.018000, warnings => qw(experimental::smartmatch);

sub parse {
    my ($self,$message) = @_;
    
    my ($token,$tag,@result);
    foreach (split(/(<|>)/,$message)) {
        when ('<') {
            $tag    = 1;
        }
        when ('>') {
            $tag    = 0;
        }
        default {
            if ($tag) {
                when ('indent') {
                    
                }
                when (/fg=([a-z0-9]+)/) {
                    
                }
                when (/bg=([a-z0-9]+)/) {
                    
                }
                when ('underline') {
                    
                }
                when ('reverse') {
                    
                }
                when ('bold') {
                    
                }
                when ('list') {
                    
                }
            }
        }
    }
    
#    <fg=green></fg>
#    <bg=rgb123></bg>
#    <underline></underline>
#    <reverse></reverse>
#    <bold></bold>
#    <indent></indent>
#    <list></list>
    
}

__PACKAGE__->meta->make_immutable;
1;