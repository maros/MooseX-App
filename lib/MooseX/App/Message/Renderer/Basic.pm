# ============================================================================
package MooseX::App::Message::Renderer::Basic;
# ============================================================================
use utf8;
use 5.010;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Renderer);

use List::Util qw(first max);

sub render {
    my ($self,@blocks) = @_;

    my $rendered = '';
    foreach my $block (@blocks) {
        $rendered .= "\n"
            if $rendered ne '';
        $rendered .= $self->render_node($block->parsed);
    }
    return $rendered;
}

sub render_node {
    my ($self,$block,$indent) = @_;

    $indent //= 0;
    my $return = '';

    foreach my $node ($block->children) {
        my $local_indent    = $indent;
        my $tag             = $node->tag;
        my $type            = $node->type || 'text';

        if ($type eq 'list') {
            my @list;
            foreach my $item ($node->children) {
                my $key     = $self->render_node(
                    (first { $_->tag eq 'key' } @{$item->{c}}),
                    -1
                );
                my $value   = first { $_->tag eq 'description' } @{$item->{c}};
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
        } elsif ($node->has_children) {
            $local_indent++
                if ($tag eq 'indent' || $tag eq 'paragraph') && $local_indent >= 0;
            my $local_return = $self->render_node($node,$local_indent);
            if ($type eq 'block') {
                chomp($local_return);
                $local_return = $self->render_text($local_return,$local_indent)."\n";
            }

            if ($tag eq 'tag') {
                $local_return = $self->render_tag($local_return,$node->{a});
            } elsif ($tag eq 'headline') {
                $local_return = $self->render_headline($local_return);
            }
            $return .= $local_return;
        } elsif (($tag eq '_text' || $tag eq 'raw')
            && $node->value) {

            $return .= $self->render_text($node->value,-1);
        }
    }

    # if ($block->{t} eq '_root') {
    #     chomp($return);
    #     chomp($return);
    #     $return .= "\n\n";
    # }

    return $return;
}


# Format output text for fixed screen width
sub render_text {
    my ($self,$text,$indent) = @_;

    $indent //= 0;
    if ($indent < 0) {
        return $text;
    }

    my $indent_pos = ($indent * $self->indent);
    my $max_length = $self->screen_width - $indent_pos;

    my @lines;
    foreach my $line (split(/\n/,$text)) {
        push(@lines,MooseX::App::Utils::string_split($max_length,$line));
    }

    return join(
        "\n",
        map { (' ' x $indent_pos).$_ }
        @lines
    );
}

sub render_tag {
    my ($self,$value,$tag) = @_;
    if ($tag eq 'bold') {
        return '*'.$value.'*';
    } elsif ($tag eq 'italic') {
        return '_'.$value.'_';
    } elsif ($tag eq 'code') {
        return '"'.$value.'"';
    }
    return $value;
}

sub render_list_key {
    my ($self,$value) = @_;
    return $value;
}

sub render_list_value {
    my ($self,$value) = @_;
    return $value;
}

sub render_headline {
    my ($self,$value) = @_;
    return $value;
}

# Format bullet list for fixed screen width
sub render_list {
    my ($self,$indent,$list,$list_indent) = @_;

    $list_indent            //= 0;
    $indent                 //= 0;
    my $space               = 2;
    my $max_length          = max(map { MooseX::App::Utils::string_length($_->key) } @{$list});
    my $description_length  = $self->screen_width - $max_length - $space - ($self->indent * ($indent+$list_indent)) - 1;
    my $prefix_length       = $max_length + ($indent * $self->indent) + $space;
    my @return;

    # Loop all items
    foreach my $element (@{$list}) {
        my $description = $element->value // '';
        my @lines = MooseX::App::Utils::string_split($description_length,$description);

        push (@return,
            (' ' x ($indent * $self->indent) )
            #.sprintf('%-*s  %s',
            #    $max_length,
            .$self->render_list_key($element->key)
            .(' ' x ($max_length - MooseX::App::Utils::string_length($element->key) + $space) )
            .$self->render_list_value(shift(@lines))
        );
        while (my $line = shift @lines) {
            push(@return,' ' x $prefix_length.$self->render_list_value($line));
        }
    }
    return join("\n",@return);
}


__PACKAGE__->meta->make_immutable;
1;