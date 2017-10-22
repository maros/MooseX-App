# ============================================================================
package MooseX::App::Message::Renderer::Basic;
# ============================================================================
use utf8;
use 5.010;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Renderer);

use List::Util qw(first);

sub render {
    my ($self,$blocks) = @_;

    my $rendered = '';
    foreach my $block (@{$blocks}) {
        $rendered .= "\n"
            if $rendered ne '';
        $rendered .= $self->render_node($block->parsed);
    }
    return $rendered;
}

sub render_node {
    my ($self,$block,$indent) = @_;

# use Data::Dumper;
# warn Data::Dumper::Dumper($block)
#     if $block->{t} eq 'root';

    $indent //= 0;
    my $return = '';

    foreach my $node (@{$block->{c}}) {
        my $local_indent    = $indent;
        my $tag             = $node->{t};
        my $type            = $MooseX::App::Message::Block::KEYWORDS{$tag}{type} || 'text';

        if ($tag eq 'list') {
            my @list;
            foreach my $item (@{$node->{c}}) {
                my $key     = $self->render_node(
                    (first { $_->{t} eq 'key' } @{$item->{c}}),
                    -1
                );
                my $value   = first { $_->{t} eq 'description' } @{$item->{c}};
                if ($value) {

                    #use Data::Dumper;
                    #say Data::Dumper::Dumper($value);
                    $value = $self->render_node($value,-1);
                    chomp($value);
                }
                chomp($key);
                push(@list,{ k => $key, v => $value });
            }

            $return .= $self->render_list(0,\@list,$indent)."\n";
        } elsif ($node->{c}) {
            $local_indent++
                if ($tag eq 'indent' || $tag eq 'paragraph') && $local_indent >= 0;
            my $local_return = $self->render_node($node,$local_indent);
            if ($type eq 'block') {
                chomp($local_return);
                $local_return = $self->render_text($local_return,$local_indent)."\n";
            }
            $return .= $local_return;
        } elsif (($tag eq '_text' || $tag eq 'raw')
            && $node->{v}) {

            $return .= $self->render_text($node->{v},-1);
        }
    }

    # if ($block->{t} eq '_root') {
    #     chomp($return);
    #     chomp($return);
    #     $return .= "\n\n";
    # }

    return $return;
}

__PACKAGE__->meta->make_immutable;
1;